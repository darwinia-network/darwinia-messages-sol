// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../interfaces/ILightClientBridge.sol";
import "../interfaces/IOutboundChannel.sol";

// BasicOutboundChannel is a basic channel that just sends messages with a nonce.
contract BasicOutboundChannel is IOutboundChannel, AccessControl {

    /**
     * Notifies an observer that the message has accepted
     * @param sourceAccount The source contract address which send the message
     * @param targetContract The targe derived DVM address of pallet ID which receive the message
     * @param channelContract The outbound channel contract address which the message commuting to
     * @param nonce The ID used to uniquely identify the message
     * @param payload The calldata which encoded by ABI Encoding, abi.encodePacked(SELECTOR, PARAMS)
     */
    event MessageAccepted(uint256 indexed nonce, address sourceAccount, address targetContract, address channelContract, bytes payload);
    event MessagesDelivered(uint256 indexed nonce, bool indexed result);
    event MessagePruned(uint256 indexed nonce);

    struct BeefyMMRLeaf {
        bytes32 parentHash;
        bytes32 chainMessagesRoot;
        uint32 blockNumber;
    }

    bytes32 public constant OUTBOUND_ROLE = keccak256("OUTBOUND_ROLE");

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
     * Hash of the InboundLaneData Schema
     * keccak256(abi.encodePacked(
     *     "InboundLaneData(uint256 lastDeliveredNonce,bytes32 messagesHash)"
     *     ")"
     * )
     */
    bytes32 public constant INBOUNDLANEDATA_TYPETASH = 0x54fe6a2dce20f4c0c068b32ba323865c047ce85a18de6aa3a48bbe4fba4c5284;

    /* State */

    enum Status {
        ACCEPTED,
        DISPATCHED,
        DELIVERED
    }

    struct Message {
        Status status;
        bytes32 infoHash;
        bool dispatchResult;
    }

    struct InboundLaneData {
        uint256 lastDeliveredNonce;
        Message[] msgs;
    }

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

	// Nonce of the latest message, received by bridged chain.
    uint256 public latestReceivedNonce;
	// Nonce of the latest message, generated by us.
    uint256 public latestGeneratedNonce;

    // nonce => message
    mapping(uint256 => Message) messages;

    constructor(
        uint256 _chainPosition,
        uint256 _lanePosition,
        uint256 _oldestUnprunedNonce,
        uint256 _latestReceivedNonce,
        uint256 _latestGeneratedNonce,
        ILightClientBridge _lightClientBridge
    ) public {
        lightClientBridge = _lightClientBridge;
        chainPosition = _chainPosition;
        lanePosition = _lanePosition;
        latestReceivedNonce = _latestReceivedNonce;
        latestGeneratedNonce = _latestGeneratedNonce;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Sends a message across the channel
     */
    function sendMessage(address targetContract, bytes calldata payload) external override {
        require(hasRole(OUTBOUND_ROLE, msg.sender), "Channel: not-authorized");
        uint256 nonce = latestGeneratedNonce + 1;
        latestGeneratedNonce = nonce;
        bytes32 messageHash = keccak256(
            abi.encode(
                MESSAGEINFO_TYPEHASH,
                nonce,
                msg.sender,
                targetContract,
                address(this),
                payload
            )
        );
        messages[nonce] = Message({
            status: Status.ACCEPTED,
            hash: messageHash,
            dispatchResult: false
        });
        // TODO:: callback `on_messages_accepted`
        emit MessageAccepted(nonce, msg.sender, targetContract, address(this), payload);
    }

    function receiveMessagesDeliveryProof(
        bytes32 outboundLaneDataHash,
        InboundLaneData memory inboundLaneData,
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
        verifyMessages(outboundLaneDataHash, inboundLaneData, beefyMMRLeaf, chainCount, chainMessagesProof, channelMessagesRoot, channelCount, channelMessagesProof);
        confirmDelivery(inboundLaneData);
    }

    function verifyMessages(
        bytes32  outboundLaneDataHash,
        InboundLaneData memory inboundLaneData,
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
            validateMessagesMatchRoot(outboundLaneDataHash, inboundLaneData, leaf.chainMessagesRoot, chainCount, chainMessagesProof, channelMessagesRoot, channelCount, channelMessagesProof),
            "Channel: invalid messages"
        );
    }

    function validateMessagesMatchRoot(
        bytes32 outboundLaneDataHash,
        InboundLaneData memory inboundLaneData,
        bytes32 chainMessagesRoot,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 channelMessagesRoot,
        uint256 channelCount,
        bytes32[] memory channelMessagesProof
    ) internal view returns (bool) {
        bytes32 messagesHash = hashLaneData(outboundLaneDataHash, inboundLaneData);
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
                    message.infoHash,
                    message.dispatchResult
                )
            );
        }
        return keccak256(encoded);
    }

    function hashInboundLaneData(InboundLaneData memory inboundLaneData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                    abi.encode(
                        INBOUNDLANEDATA_TYPETASH,
                        inboundLaneData.latestReceivedNonce,
                        hashMessages(inboundLaneData.msgs)
                    )
                );
    }

    function hashLaneData(bytes32 outboundLaneDataHash, InboundLaneData memory inboundLaneData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                    abi.encodePacked(
                        outboundLaneDataHash,
                        hashInboundLaneData(inboundLaneData)
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

    function confirmDelivery(InboundLaneData memory inboundLaneData) internal {
        uint256 latest_delivered_nonce = inboundLaneData.lastDeliveredNonce;
        require(latest_delivered_nonce > latestReceivedNonce, "Channel: no new confirmations");
        require(latest_delivered_nonce <= latestGeneratedNonce, "Channel: future messages");
        uint256 nonce = latestReceivedNonce + 1;
        for (uint256 i = nonce; i <= latest_delivered_nonce; i++) {
            Message storage message = messages[i];
            Message memory newMsg = inboundLaneData.msgs[i];
            require(message.nonce == nonce, "Channel: invalid nonce");
            require(message.nonce == newMsg.nonce, "Channel: invalid nonce");
            require(newMsg.Status == Status.DISPATCHED, "Channel: message should dispatched");
            message.Status = DELIVERED;
            message.dispatchResult = newMsg.dispatchResult;
            // TODO: may need a callback, such as `on_messages_delivered`
            emit MessagesDelivered(nonce, message.dispatchResult);
            // pruneMessage(nonce);
            delete messages[nonce];
        }
        latestReceivedNonce = nonce;
    }

}
