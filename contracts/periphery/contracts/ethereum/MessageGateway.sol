// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IOutboundLane.sol";
import "../interfaces/IFeeMarket.sol";
import "../interfaces/ICrossChainFilter.sol";
import "../interfaces/IMessageGateway.sol";
import "../interfaces/IMessageReceiver.sol";

contract MessageGateway is IMessageGateway, ICrossChainFilter {
    address creator;
    address public remoteGateway;
    address public outboundLane;
    address public feeMarket;

    event FailedMessage(address from, address to, bytes message, string reason);

    constructor(address _outboundLane, address _feeMarket) {
        outboundLane = _outboundLane;
        feeMarket = _feeMarket;
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

    ////////////////////////////////////////////////////
    // To Remote
    ////////////////////////////////////////////////////
    function fee() public view returns (uint256) {
        return IFeeMarket(feeMarket).market_fee();
    }

    function send(
        address to,
        bytes memory message
    ) external payable returns (uint64 nonce) {
        uint256 paid = msg.value;
        uint256 marketFee = fee();
        require(paid >= marketFee, "!fee");

        // refund fee to caller if paid too much.
        if (paid > marketFee) {
            // refund fee to caller.
            payable(msg.sender).transfer(paid - marketFee);
        }

        // remote call `recv(from,to,message)` on remoteGateway
        bytes memory receiveCall = abi.encodeWithSignature(
            "recv(address,address,bytes)", // this is the function of remoteGateway.
            address(msg.sender), // from, or this?
            to,
            message
        );
        return
            IOutboundLane(outboundLane).send_message{value: marketFee}(
                remoteGateway,
                receiveCall
            );
    }

    ////////////////////////////////////////////////////
    // From Remote
    ////////////////////////////////////////////////////
    function cross_chain_filter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata payload
    ) external view returns (bool) {
        return true;
    }

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
