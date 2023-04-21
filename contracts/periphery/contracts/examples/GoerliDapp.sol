// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IMessageSender.sol";

contract GoerliDapp {
    IMessageSender public messageSender;

    constructor(address _messageSender) {
        messageSender = IMessageSender(_messageSender);
    }

    function remoteAddOn(address pangolinDapp, uint256 value) external payable {
        bytes memory message = abi.encode(value);
        messageSender.send(pangolinDapp, message);
    }
}
