// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../interfaces/ILightClientBridge.sol";

contract BasicLane {

    /**
     * Hash of the MessageInfo Schema
     * keccak256(abi.encodePacked(
     *     "MessageInfo(uint256 nonce,address sourceAccount,address targetContract,address channelContract,bytes payload)"
     *     ")"
     * )
     */
    bytes32 public constant MESSAGEINFO_TYPEHASH = 0x875eb7edeec63d096eb4a18d42ce11cbb92aa599ce7fef87dfc12ffe08dd79b5;

    /**
     * Hash of the Message Schema
     * keccak256(abi.encodePacked(
     *     "Message(Status status,bytes32 infoHash,bool dispatchResult)"
     *     ")"
     * )
     */
    bytes32 public constant MESSAGE_TYPEHASH = 0x85750a81522861eac690c0069b9cd0df956555451fc936325575e0139150c4e2;

    /**
     * The MessageInfo is the structure of DarwiniaRPC which should be delivery to Ethereum-like chain
     * @param sourceAccount The derived DVM address of pallet ID which send the message
     * @param targetContract The targe contract address which receive the message
     * @param laneContract The inbound lane contract address which the message commuting to
     * @param nonce The ID used to uniquely identify the message
     * @param payload The calldata which encoded by ABI Encoding
     */
    struct MessageInfo {
        uint256 nonce;
        address sourceAccount;
        address targetContract;
        address laneContract;
        bytes payload; /*abi.encodePacked(SELECTOR, PARAMS)*/
    }

    enum Status {
        ACCEPTED,
        DISPATCHED,
        DELIVERED
    }

    struct Message {
        Status status;
        MessageInfo info;
        bool dispatchResult;
    }

    struct MessageStorage {
        Status status;
        bytes32 infoHash;
        bool dispatchResult;
    }

    /**
     * The BeefyMMRLeaf is the structure of each leaf in each MMR that each commitment's payload commits to.
     * @param parentHash parent hash of the block this leaf describes
     * @param chainMessagesRoot  chain message root is a two-level Merkle tree consisting of all messages from different chains and different channels, chainMessagesRoot is the root hash of `chain_messages_merkle_tree`, and the leaves of `chain_messages_merkle_tree` are messages root of different chains, they form the first level of merkle tree, `channel_messages_root` is the root hash of `channel_messages_merkle_tree`, and the leaves of `channel_messages_merkle_tree` are the hashes of the message collections of different channels, which form the second level of the merkle tree.
     * @param blockNumber block number for the block this leaf describes
     */
    struct BeefyMMRLeaf {
        bytes32 parentHash;
        bytes32 chainMessagesRoot;
        uint32 blockNumber;
    }

    /* State */
    /**
     * @dev The contract address of on-chain light client
     */
    ILightClientBridge public lightClientBridge;

    /**
     * @dev The position of the leaf in the `chain_message_merkle_tree`, index starting with 0
     */
    uint256 public chainPosition;

    /**
     * @dev The position of the leaf in the `channel_messages_merkle_tree`, index starting with 0
     */
    uint256 public lanePosition;

    /* Private Functions */

    function verifyMMRLeaf(
        BeefyMMRLeaf memory beefyMMRLeaf,
        uint256 beefyMMRLeafIndex,
        uint256 beefyMMRLeafCount,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) internal
      view
    {
        require(
            lightClientBridge.verifyBeefyMerkleLeaf(
                hash(beefyMMRLeaf),
                beefyMMRLeafIndex,
                beefyMMRLeafCount,
                peaks,
                siblings
            ),
            "Channel: Invalid proof"
        );
    }

    function verifyMessages(
        bytes32  outboundLaneDataHash,
        bytes32  inboundLaneDataHash,
        BeefyMMRLeaf memory leaf,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 channelMessagesRoot,
        uint256 channelCount,
        bytes32[] memory channelMessagesProof
    )
        internal
        view
    {
        require(
            leaf.blockNumber <= lightClientBridge.getFinalizedBlockNumber(),
            "Channel: block not finalized"
        );
        // Validate that the commitment matches the commitment contents
        require(
            validateMessagesMatchRoot(
                outboundLaneDataHash,
                inboundLaneDataHash,
                leaf.chainMessagesRoot,
                chainCount,
                chainMessagesProof,
                channelMessagesRoot,
                channelCount,
                channelMessagesProof
            ),
            "Channel: invalid messages"
        );
    }

    function validateMessagesMatchRoot(
        bytes32 outboundLaneDataHash,
        bytes32 inboundLaneDataHash,
        bytes32 chainMessagesRoot,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 channelMessagesRoot,
        uint256 channelCount,
        bytes32[] memory channelMessagesProof
    ) internal view returns (bool) {
        bytes32 laneHash = hash(outboundLaneDataHash, inboundLaneDataHash);
        return
            MerkleProof.verifyMerkleLeafAtPosition(
                channelMessagesRoot,
                laneHash,
                lanePosition,
                channelCount,
                channelMessagesProof
            )
            &&
            MerkleProof.verifyMerkleLeafAtPosition(
                chainMessagesRoot,
                channelMessagesRoot,
                lanePosition,
                chainCount,
                chainMessagesProof
            );
    }

    function hash(BeefyMMRLeaf memory leaf)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                abi.encodePacked(
                    leaf.parentHash,
                    leaf.chainMessagesRoot,
                    leaf.blockNumber
                )
            );
    }

    function hash(bytes32 outboundChannelDataHash, bytes32 inboundLaneDataHash)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                    abi.encodePacked(
                        outboundChannelDataHash,
                        inboundLaneDataHash
                    )
                );
    }

    function hash(Message[] memory msgs)
        internal
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(msgs.length);
        for (uint256 i = 0; i < msgs.length; i ++) {
            Message memory message = msgs[i];
            encoded = abi.encodePacked(
                encoded,
                abi.encode(
                    MESSAGE_TYPEHASH,
                    message.status,
                    hash(message.info),
                    message.dispatchResult
                )
            );
        }
        return keccak256(encoded);
    }

    function hash(MessageInfo memory message)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                abi.encode(
                    MESSAGEINFO_TYPEHASH,
                    message.nonce,
                    message.sourceAccount,
                    message.targetContract,
                    message.laneContract,
                    message.payload
                )
            );
    }
}

