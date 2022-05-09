// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

abstract contract PangoroSmartChainXApp {
    using SmartChainXLib for SmartChainXLib.Channel;

    SmartChainXLib.Channel pangolinChannel = SmartChainXLib.Channel(bytes2(0x2b03), 0, 28110);

    function sendMessageToPangolin(uint256 deliveryAndDispatchFee, uint64 callWeight, bytes memory callEncoded) internal {
        bytes memory message = pangolinChannel.buildMessage(callWeight, callEncoded);
        pangolinChannel.sendMessage(deliveryAndDispatchFee, message);
    }
}