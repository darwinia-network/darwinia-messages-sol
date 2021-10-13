// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-utils/contracts/SafeMath.sol";
import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../interfaces/ILightClientBridge.sol";
import "../interfaces/ICrossChainFilter.sol";

/**
 * @title A entry contract for syncing message from Darwinia to Ethereum-like chain
 * @author echo
 * @notice The basic inbound lane is the message layer of the bridge
 * @dev See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52
 */
contract BasicInboundLane {
    /**
     * @notice Notifies an observer that the message has dispatched
     * @param nonce The message nonce
     * @param result The message result
     * @param returndata The return data of message call, when return false, it's the reason of the error
     */
    event MessageDispatched(uint256 indexed nonce, bool indexed result, bytes returndata);
    event MessagePruned(uint256 indexed nonce);

    /* Constants */
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
     * Hash of the OutboundLaneData Schema
     * keccak256(abi.encodePacked(
     *     "OutboundLaneData(uint256 latestReceivedNonce,bytes32 messagesHash)"
     *     ")"
     * )
     */
    bytes32 public constant OUTBOUNDLANEDATA_TYPETASH = 0x54fe6a2dce20f4c0c068b32ba323865c047ce85a18de6aa3a48bbe4fba4c5284;
    /**
     * @dev Gas used per message needs to be less than 100000 wei
     */
    uint256 public constant MAX_GAS_PER_MESSAGE = 100000;
    /**
     * @dev Gas buffer for executing `submit` tx
     */
    uint256 public constant GAS_BUFFER = 60000;

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

    struct OutboundLaneData {
        uint256 latestReceivedNonce;
        Message[] msgs;
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

    /**
     * @dev ID of the next message, which is incremented in strict order
     * @notice When upgrading the channel, this value must be synchronized
     */
    uint256 public lastConfirmedNonce;

    uint256 public lastDeliveredNonce;

    // nonce => message
    mapping(uint256 => Message) messages;

    /**
     * @notice Deploys the BasicInboundChannel contract
     * @param _chainPosition The position of the leaf in the `chain_messages_merkle_tree`, index starting with 0
     * @param _lanePosition The position of the leaf in the `channel_messages_merkle_tree`, index starting with 0
     * @param _lightClientBridge The contract address of on-chain light client
     */
    constructor(uint256 _chainPosition, uint256 _lanePosition, uint256 _lastConfirmedNonce, uint256 _lastDeliveredNonce, ILightClientBridge _lightClientBridge) public {
        chainPosition = _chainPosition;
        lanePosition = _lanePosition;
        lastConfirmedNonce = _lastConfirmedNonce;
        lastDeliveredNonce = _lastDeliveredNonce;
        lightClientBridge = _lightClientBridge;
    }

    /* Public Functions */

    /**
     * @notice Deliver and dispatch the messages
     * @param chainCount Number of all chain
     * @param chainMessagesProof The merkle proof required for validation of the messages in the `chain_messages_merkle_tree`
     * @param channelMessagesRoot The merkle root of the channels, each channel is a leaf constructed by the hash of the messages in the channel
     * @param channelCount Number of all channels
     * @param channelMessagesProof The merkle proof required for validation of the messages in the `channel_messages_merkle_tree`
     * @param beefyMMRLeaf Beefy MMR leaf which the messages root is located
     * @param beefyMMRLeafIndex Beefy MMR index which the beefy leaf is located
     * @param beefyMMRLeafCount Beefy MMR width of the MMR tree
     * @param peaks The proof required for validation the leaf
     * @param siblings The proof required for validation the leaf
     */
    function receiveMessagesProof(
        OutboundLaneData memory outboundLaneData,
        bytes32 inboundLaneDataHash,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 channelMessagesRoot,
        uint256 channelCount,
        bytes32[] memory channelMessagesProof,
        BeefyMMRLeaf memory beefyMMRLeaf,
        uint256 beefyMMRLeafIndex,
        uint256 beefyMMRLeafCount,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public {
        bytes32 beefyMMRLeafHash = hashMMRLeaf(beefyMMRLeaf);
        require(
            lightClientBridge.verifyBeefyMerkleLeaf(
                beefyMMRLeafHash,
                beefyMMRLeafIndex,
                beefyMMRLeafCount,
                peaks,
                siblings
            ),
            "Channel: Invalid proof"
        );
        verifyMessages(outboundLaneData, inboundLaneDataHash, beefyMMRLeaf, chainCount, chainMessagesProof, channelMessagesRoot, channelCount, channelMessagesProof);
        receiveStateUpdate(OutboundLaneData.latestReceivedNonce);
        dispatch(outboundLaneData.msgs);
    }

    /* Private Functions */

    function verifyMessages(
        OutboundLaneData memory outboundLaneData,
        bytes32 inboundLaneDataHash,
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
            validateMessagesMatchRoot(outboundLaneData, inboundLaneDataHash, leaf.chainMessagesRoot, chainCount, chainMessagesProof, channelMessagesRoot, channelCount, channelMessagesProof),
            "Channel: invalid messages"
        );

        // Require there is enough gas to play all messages
        require(
            gasleft() >= (messages.length * MAX_GAS_PER_MESSAGE) + GAS_BUFFER,
            "Channel: insufficient gas for delivery of all messages"
        );
    }

    function receiveStateUpdate(uint256 latest_received_nonce) internal {
        uint256 last_delivered_nonce = lastDeliveredNonce;
        uint256 last_confirmed_nonce = lastConfirmedNonce;
        require(latest_received_nonce <= lastDeliveredNonce, "Channel: invalid received nonce");
        if (latest_received_nonce > lastConfirmedNonce) {
            for (uint256 nonce = lastConfirmedNonce; nonce <= latest_received_nonce; nonce++) {
                // pruneMessage(nonce);
                delete messages[nonce];
                emit MessagePruned(nonce);
            }
        }
        lastConfirmedNonce = latest_received_nonce;
    }

    function dispatch(Message[] memory msgs) internal {
        for (uint256 i = 0; i < msgs.length; i++) {
            MessageInfo memory message = msgs[i].info;
            require(message.status == Status.ACCEPTED, "Channel: invalid message status");
            uint256 nonce = lastDeliveredNonce;
            // Check message nonce is correct and increment nonce for replay protection
            require(message.nonce == nonce + 1, "Channel: invalid nonce");
            require(message.channelContract == address(this), "Channel: invalid lane contract");

            nonce = nonce + 1;
            bool success = false;
            bytes memory returndata;

            /**
             * @notice The app layer must implement the interface `ICrossChainFilter`
             */
            try ICrossChainFilter(message.targetContract).crossChainFilter(message.sourceAccount, message.payload)
                returns (bool ok)
            {
                if (ok) {
                    // Deliver the message to the target
                    (success, returndata) =
                        message.targetContract.call{value: 0, gas: MAX_GAS_PER_MESSAGE}(
                            message.payload
                    );
                    emit MessageDispatched(message.nonce, success, returndata);
                } else {
                    emit MessageDispatched(message.nonce, false, "Channel: filter failed");
                }
            } catch (bytes memory reason) {
                emit MessageDispatched(message.nonce, false, reason);
            }

            bytes32 messageHash = keccak256(
                abi.encode(
                    MESSAGE_TYPEHASH,
                    message.sourceAccount,
                    message.targetContract,
                    message.channelContract,
                    message.nonce,
                    message.payload
                )
            );
            messages[nonce] = Message({
                status: Status.ACCEPTED,
                hash: messageHash,
                dispatchResult: success
            });
            lastDeliveredNonce = nonce;
        }
    }

    function validateMessagesMatchRoot(
        OutboundLaneData memory outboundLaneData,
        bytes32 inboundLaneDataHash,
        bytes32 chainMessagesRoot,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 channelMessagesRoot,
        uint256 channelCount,
        bytes32[] memory channelMessagesProof
    ) internal view returns (bool) {
        bytes32 messagesHash = hashLaneData(outboundLaneData, inboundLaneDataHash);
        return
            MerkleProof.verifyMerkleLeafAtPosition(
                channelMessagesRoot,
                messagesHash,
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

    function hash(Message memory message)
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

    function hashMessages(Message[] memory msgs)
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
                    hash(message),
                    message.dispatchResult
                )
            );
        }
        return keccak256(encoded);
    }

    function hashOutboundLaneData(OutboundLaneData memory outboundChannelData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                    abi.encode(
                        OUTBOUNDLANEDATA_TYPETASH,
                        outboundChannelData.latestReceivedNonce,
                        hashMessages(outboundChannelData.msgs)
                    )
                );
    }

    function hashLaneData(OutboundLaneData memory outboundChannelData, bytes32 inboundLaneHash)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                    abi.encodePacked(
                        hashOutboundLaneData(outboundChannelData),
                        inboundLaneHash
                    )
                );
    }

    function hashMMRLeaf(BeefyMMRLeaf memory leaf)
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
}
