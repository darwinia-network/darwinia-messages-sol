// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BasicLane.sol";
import "../interfaces/IOutboundLane.sol";

// BasicOutboundLand is a basic lane that just sends messages with a nonce.
contract BasicOutboundLane is IOutboundLane, AccessControl, BasicLane {

    /**
     * Notifies an observer that the message has accepted
     * @param sourceAccount The source contract address which send the message
     * @param targetContract The targe derived DVM address of pallet ID which receive the message
     * @param laneContract The outbound lane contract address which the message commuting to
     * @param nonce The ID used to uniquely identify the message
     * @param payload The calldata which encoded by ABI Encoding, abi.encodePacked(SELECTOR, PARAMS)
     */
    event MessageAccepted(uint256 indexed lanePosition, uint256 indexed nonce, address sourceAccount, address targetContract, address laneContract, bytes payload);
    event MessagesDelivered(uint256 indexed lanePosition, uint256 indexed nonce, bool indexed result);
    event MessagePruned(uint256 indexed lanePosition, uint256 indexed nonce);

    bytes32 public constant OUTBOUND_ROLE = keccak256("OUTBOUND_ROLE");

    /**
     * Hash of the InboundLaneData Schema
     * keccak256(abi.encodePacked(
     *     "InboundLaneData(uint256 lastDeliveredNonce,bytes32 messagesHash)"
     *     ")"
     * )
     */
    bytes32 public constant INBOUNDLANEDATA_TYPETASH = 0x54fe6a2dce20f4c0c068b32ba323865c047ce85a18de6aa3a48bbe4fba4c5284;

    uint256 public constant MAX_PENDING_MESSAGES = 50;

    /* State */

    struct InboundLaneData {
        uint256 lastDeliveredNonce;
        Message[] msgs;
    }

	// Nonce of the latest message, received by bridged chain.
    uint256 public latestReceivedNonce;
	// Nonce of the latest message, generated by us.
    uint256 public latestGeneratedNonce;

    // nonce => message
    mapping(uint256 => MessageStorage) messages;

    constructor(
        uint256 _chainPosition,
        uint256 _lanePosition,
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
     * @dev Sends a message across the lane
     */
    function sendMessage(address targetContract, bytes calldata payload) external override {
        require(hasRole(OUTBOUND_ROLE, msg.sender), "Lane: not-authorized");
        require(latestGeneratedNonce - latestReceivedNonce <= MAX_PENDING_MESSAGES, "Lane: Too many pending messages");
        uint256 nonce = latestGeneratedNonce + 1;
        latestGeneratedNonce = nonce;
        MessageInfo memory messageInfo = MessageInfo({
            nonce: nonce,
            sourceAccount: msg.sender,
            targetContract: targetContract,
            laneContract: address(this),
            payload: payload
        });
        messages[nonce] = MessageStorage({
            status: Status.ACCEPTED,
            infoHash: hash(messageInfo),
            dispatchResult: false
        });
        // TODO:: callback `on_messages_accepted`
        emit MessageAccepted(lanePosition, messageInfo.nonce, messageInfo.sourceAccount, messageInfo.targetContract, messageInfo.laneContract, messageInfo.payload);
    }

    function receiveMessagesDeliveryProof(
        bytes32 outboundLaneDataHash,
        InboundLaneData memory inboundLaneData,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 laneMessagesRoot,
        uint256 laneCount,
        bytes32[] memory laneMessagesProof,
        BeefyMMRLeaf memory beefyMMRLeaf,
        uint256 beefyMMRLeafIndex,
        uint256 beefyMMRLeafCount,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public {
        verifyMMRLeaf(beefyMMRLeaf, beefyMMRLeafIndex, beefyMMRLeafCount, peaks, siblings);
        verifyMessages(
            outboundLaneDataHash,
            hash(inboundLaneData),
            beefyMMRLeaf,
            chainCount,
            chainMessagesProof,
            laneMessagesRoot,
            laneCount,
            laneMessagesProof
        );
        confirmDelivery(inboundLaneData);
    }

    /* Private Functions */

    function confirmDelivery(InboundLaneData memory inboundLaneData) internal {
        uint256 latest_delivered_nonce = inboundLaneData.lastDeliveredNonce;
        require(latest_delivered_nonce > latestReceivedNonce, "Lane: no new confirmations");
        require(latest_delivered_nonce <= latestGeneratedNonce, "Lane: future messages");
        require(latest_delivered_nonce - latestReceivedNonce <= inboundLaneData.msgs.length, "Lane: invalid messages size");
        for (uint256 i = 0; i < inboundLaneData.msgs.length; i++) {
            uint256 nonce = latestReceivedNonce + 1;
            Message memory newMsg = inboundLaneData.msgs[i];
            if (newMsg.info.nonce < nonce) {
                continue;
            }
            require(newMsg.status == Status.DISPATCHED, "Lane: message should dispatched");
            require(newMsg.info.nonce == nonce, "Lane: invalid nonce");
            MessageStorage storage message = messages[i];
            require(message.infoHash == hash(newMsg.info), "Lane: invalid message hash");
            message.status = Status.DELIVERED;
            message.dispatchResult = newMsg.dispatchResult;
            // TODO: may need a callback, such as `on_messages_delivered`
            emit MessagesDelivered(lanePosition, nonce, message.dispatchResult);
            pruneMessage(nonce);
            latestReceivedNonce = nonce;
        }
    }

    function pruneMessage(uint256 nonce) internal {
        delete messages[nonce];
        emit MessagePruned(lanePosition, nonce);
    }

    function hash(InboundLaneData memory inboundLaneData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                    abi.encode(
                        INBOUNDLANEDATA_TYPETASH,
                        inboundLaneData.lastDeliveredNonce,
                        hash(inboundLaneData.msgs)
                    )
                );
    }
}
