// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../AccessController.sol";
import "../../interfaces/ICrossChainFilter.sol";
import "../../interfaces/IFeeMarket.sol";
import "../../interfaces/IHelixApp.sol";
import "../../interfaces/IHelixMessageHandleSupportingConfirm.sol";
import "../../interfaces/IInboundLane.sol";
import "../../interfaces/IMessageCommitment.sol";
import "../../interfaces/IOutboundLane.sol";

contract DarwiniaMessageHandle is IHelixMessageHandleSupportingConfirm, ICrossChainFilter, AccessController {
    address public feeMarket;
    uint32  public remoteChainPosition;
    address public remoteHelix;

    address public inboundLane;
    address public outboundLane;

    mapping(uint256 => address) public messageWaitingConfirm;

    event NewInBoundLaneAdded(uint32 bridgedLanePosition, address inboundLane);
    event NewOutBoundLaneAdded(uint32 bridgedLanePosition, address outboundLane);

    constructor() {
        _initialize(msg.sender);
    }

    modifier onlyRemoteHelix(address _remoteHelix) {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(msg.sender).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "DarwiniaMessageHandle:Invalid bridged chain position");
        require(remoteHelix == _remoteHelix, "DarwiniaMessageHandle:remote caller is not helix sender allowed");
        require(inboundLane == msg.sender, "DarwiniaMessageHandle:caller is not the inboundLane account");
        _;
    }

    modifier onlyOutBoundLane() {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(msg.sender).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "DarwiniaMessageHandle:Invalid bridged chain position");
        require(outboundLane == msg.sender, "DarwiniaMessageHandle:caller is not the outboundLane account");
        _;
    }

    function setFeeMarket(address newFeeMarket) external onlyAdmin {
        feeMarket = newFeeMarket;
    }

    function setBridgeInfo(uint32 _bridgedChainPosition, address _remoteHelix) external onlyAdmin {
        remoteChainPosition = _bridgedChainPosition;
        remoteHelix = _remoteHelix;
    }

    // here add InBoundLane, and remote issuing module must add the corresponding OutBoundLane
    function setInboundLane(address _inboundLane) external onlyAdmin {
        inboundLane = _inboundLane;
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(inboundLane).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "DarwiniaMessageHandle:Invalid bridged chain position");
        emit NewInBoundLaneAdded(bridgedLanePosition, inboundLane);
    }

    // here add OutBoundLane, and remote issuing module must add the corresponding InBoundLane
    function setOutboundLane(address _outboundLane) external onlyAdmin {
        outboundLane = _outboundLane;
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(outboundLane).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "DarwiniaMessageHandle:Invalid bridged chain position");
        emit NewOutBoundLaneAdded(bridgedLanePosition, outboundLane);
    }

    function crossChainFilter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata
    ) external view returns (bool) {
        return remoteChainPosition == bridgedChainPosition && inboundLane == msg.sender && remoteHelix == sourceAccount;
    }

    function sendMessage(address receiver, bytes calldata message) external onlyCaller payable returns (uint256) {
        bytes memory messageWithCaller = abi.encodeWithSelector(
            DarwiniaMessageHandle.recvMessage.selector,
            address(this),
            receiver,
            message
        );
        uint256 fee = IFeeMarket(feeMarket).market_fee();
        require(msg.value >= fee, "DarwiniaMessageHandle:not enough fee to pay");
        uint256 messageId = IOutboundLane(outboundLane).send_message{value: fee}(remoteHelix, messageWithCaller);
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
        messageWaitingConfirm[messageId] = msg.sender;
        return messageId;
    }

    function recvMessage(
        address sender,
        address receiver,
        bytes calldata message
    ) external onlyRemoteHelix(sender) whenNotPaused {
        require(hasRole(CALLER_ROLE, receiver), "DarwiniaMessageHandle:receiver is not caller");
        (bool result,) = receiver.call{value: 0}(message);
        require(result, "DarwiniaMessageHandle:call app failed");
    }

    function latestRecvMessageId() external view returns(uint256) {
        IInboundLane.InboundLaneNonce memory inboundLaneNonce = IInboundLane(inboundLane).inboundLaneNonce();
        // todo we should transform this messageId to bridged outboundLane messageId
        uint256 messageId = IInboundLane(inboundLane).encodeMessageKey(inboundLaneNonce.last_delivered_nonce);
        return messageId;
    }

    function on_messages_delivered(
        uint256 messageId,
        bool result
    ) external onlyOutBoundLane {
        address caller = messageWaitingConfirm[messageId];
        if (caller != address(0)) {
            IHelixAppSupportConfirm(caller).onMessageDelivered(messageId, result);
        }
        delete messageWaitingConfirm[messageId];
    }
}

