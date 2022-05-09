// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

abstract contract CrabSmartChainXApp {
    using SmartChainXLib for SmartChainXLib.Channel;

    SmartChainXLib.Channel darwiniaChannel = SmartChainXLib.Channel(bytes2(0x3003), 0, 1200);

    function sendMessageToDarwinia(uint256 deliveryAndDispatchFee, uint64 callWeight, bytes memory callEncoded) internal {
        bytes memory message = darwiniaChannel.buildMessage(callWeight, callEncoded);
        darwiniaChannel.sendMessage(deliveryAndDispatchFee, message);
    }
}