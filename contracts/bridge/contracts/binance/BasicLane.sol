// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../interfaces/ILightClientBridge.sol";

contract BasicLane {

    /**
     * Hash of the MessageInfo Schema
     * keccak256(abi.encodePacked(
     *     "MessageInfo(uint256 nonce,address sourceAccount,address targetContract,address laneContract,bytes payload)"
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
     * Hash of the LaneData Schema
     * keccak256(abi.encodePacked(
     *     "LaneData(bytes32 outboundLaneDataHash,bytes32 inboundLaneDataHash)"
     *     ")"
     * )
     */
    bytes32 public constant LANEDATA_TYPEHASH = 0x8f6ab5f61c30d2037b3accf5c8898c9242d2acc51072316f994ac5d6748dd567;

    /**
     * Hash of the BeefyMMRLeaf Schema
     * keccak256(abi.encodePacked(
     *     "BeefyMMRLeaf(bytes32 parentHash,bytes32 chainMessagesRoot,uint32 blockNumber)"
     *     ")"
     * )
     */
    bytes32 public constant BEEFYMMRLEAF_TYPEHASH = 0x344720a031552a825254ba106025d2909e0f38c0116c1aa520eed4e00ad8e215;

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
     * @param chainMessagesRoot  chain message root is a two-level Merkle tree consisting of all messages from different chains and different lanes, chainMessagesRoot is the root hash of `chain_messages_merkle_tree`, and the leaves of `chain_messages_merkle_tree` are messages root of different chains, they form the first level of merkle tree, `lane_messages_root` is the root hash of `lane_messages_merkle_tree`, and the leaves of `lane_messages_merkle_tree` are the hashes of the message collections of different lanes, which form the second level of the merkle tree.
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
     * @dev The position of the leaf in the `lane_messages_merkle_tree`, index starting with 0
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
            "Lane: Invalid proof"
        );
    }

    function verifyMessages(
        bytes32  outboundLaneDataHash,
        bytes32  inboundLaneDataHash,
        BeefyMMRLeaf memory leaf,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 laneMessagesRoot,
        uint256 laneCount,
        bytes32[] memory laneMessagesProof
    )
        internal
        view
    {
        require(
            leaf.blockNumber <= lightClientBridge.getFinalizedBlockNumber(),
            "Lane: block not finalized"
        );
        // Validate that the commitment matches the commitment contents
        require(
            validateMessagesMatchRoot(
                outboundLaneDataHash,
                inboundLaneDataHash,
                leaf.chainMessagesRoot,
                chainCount,
                chainMessagesProof,
                laneMessagesRoot,
                laneCount,
                laneMessagesProof
            ),
            "Lane: invalid messages"
        );
    }

    function validateMessagesMatchRoot(
        bytes32 outboundLaneDataHash,
        bytes32 inboundLaneDataHash,
        bytes32 chainMessagesRoot,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 laneMessagesRoot,
        uint256 laneCount,
        bytes32[] memory laneMessagesProof
    ) internal view returns (bool) {
        bytes32 laneHash = hash(outboundLaneDataHash, inboundLaneDataHash);
        return
            MerkleProof.verifyMerkleLeafAtPosition(
                laneMessagesRoot,
                laneHash,
                lanePosition,
                laneCount,
                laneMessagesProof
            )
            &&
            MerkleProof.verifyMerkleLeafAtPosition(
                chainMessagesRoot,
                laneMessagesRoot,
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
                    BEEFYMMRLEAF_TYPEHASH,
                    leaf.parentHash,
                    leaf.chainMessagesRoot,
                    leaf.blockNumber
                )
            );
    }

    function hash(bytes32 outboundLaneDataHash, bytes32 inboundLaneDataHash)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                    abi.encodePacked(
                        LANEDATA_TYPEHASH,
                        outboundLaneDataHash,
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

