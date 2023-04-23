// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IMessageSendingService.sol";
import "./interfaces/IOutboundLane.sol";

contract DarwiniaSendingService is IMessageSendingService {
    address public outboundLane;
    address public feeMarket;

    constructor(address _outboundLane, address _feeMarket) {
        outboundLane = _outboundLane;
        feeMarket = _feeMarket;
    }

    function send(
        address _messageReceivingService,
        address _remoteDappAddress,
        bytes calldata _message
    ) external payable {
        // remote call `recv(from,to,message)` on receivingService
        bytes memory recvCall = abi.encodeWithSignature(
            "recv(address,address,bytes)",
            address(msg.sender), // from, user dapp
            _remoteDappAddress,
            _message
        );
        IOutboundLane(outboundLane).send_message{value: msg.value}(
            _messageReceivingService,
            _recvCall
        );
    }

    function estimateFee() external view returns (uint256) {
        return IFeeMarket(feeMarket).market_fee();
    }
}
