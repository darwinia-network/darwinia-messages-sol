// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IOutboundLane.sol";
import "../interfaces/IFeeMarket.sol";
import "../interfaces/ICrossChainFilter.sol";
import "../interfaces/IMessageReceiver.sol";

contract EthereumMessageEndpoint is ICrossChainFilter {
    address public immutable REMOTE_ENDPOINT;
    address public immutable OUTBOUND_LANE;
    address public immutable FEE_MARKET;

    event FailedMessage(address from, address to, bytes message, string reason);

    constructor(
        address _remoteEndpoint,
        address _outboundLane,
        address _feeMarket
    ) {
        REMOTE_ENDPOINT = _remoteEndpoint;
        OUTBOUND_LANE = _outboundLane;
        FEE_MARKET = _feeMarket;
    }

    ////////////////////////////////////////////////////
    // To Remote
    ////////////////////////////////////////////////////
    function fee() public view returns (uint256) {
        return IFeeMarket(FEE_MARKET).market_fee();
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

        // remote call `recv(from,to,message)` on REMOTE_ENDPOINT
        bytes memory receiveCall = abi.encodeWithSignature(
            "recv(address,address,bytes)", // this is the function of REMOTE_ENDPOINT.
            address(msg.sender), // from, or this?
            to,
            message
        );
        return
            IOutboundLane(OUTBOUND_LANE).send_message{value: marketFee}(
                REMOTE_ENDPOINT,
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
