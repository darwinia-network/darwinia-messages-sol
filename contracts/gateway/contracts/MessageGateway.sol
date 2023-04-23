// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IFeeMarket.sol";
import "./interfaces/IMessageGateway.sol";
import "./interfaces/IMessageReceiver.sol";
import "./interfaces/IMessageSendingService.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract MessageGateway is IMessageGateway {
    address creator;
    address public messageSendingService;
    address public messageReceivingService;

    event FailedMessage(address from, address to, bytes message, string reason);

    constructor() {
        creator = msg.sender;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    function setRemoteGateway(address _remoteGateway) external onlyCreator {
        remoteGateway = _remoteGateway;
    }

    function setFeeMarket(address _feeMarket) external onlyCreator {
        feeMarket = _feeMarket;
    }

    function setOutboundLane(address _outboundLane) external onlyCreator {
        outboundLane = _outboundLane;
    }

    function setMessagingService(
        address _messageSendingService,
        address _messageReceivingService
    ) external onlyCreator {
        messageSendingService = _messageSendingService;
        messageReceivingService = _messageReceivingService;
    }

    ////////////////////////////////////////////////////
    // To Remote
    ////////////////////////////////////////////////////
    // User Dapp will call this function.
    function send(
        address remoteDappAddress,
        bytes memory message
    ) external payable returns (uint64 nonce) {
        uint256 paid = msg.value;
        uint256 marketFee = IMessageSendingService(messageSendingService)
            .estimateFee();
        require(paid >= marketFee, "!fee");

        // refund fee to caller if paid too much.
        if (paid > marketFee) {
            // refund fee to caller.
            payable(msg.sender).transfer(paid - marketFee);
        }

        IMessageSendingService(messageSendingService).send(
            messageReceivingService,
            remoteDappAddress,
            message
        );
    }

    ////////////////////////////////////////////////////
    // From Remote
    ////////////////////////////////////////////////////
    function recv(address from, address to, bytes memory message) external {
        // this will catch all errors from user's receive function.
        try IMessageReceiver(to).recv(from, message) {
            // call user's receive function successfully.
        } catch Error(string memory reason) {
            // call user's receive function failed by uncaught error.
            // store the message and error for the user to do something like retry.
            emit FailedMessage(from, to, message, reason);
        } catch (bytes memory lowLevelData) {
            emit FailedMessage(from, to, message, string(lowLevelData));
        }
    }
}
