// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

abstract contract PangoroSmartChainXApp {
    using SmartChainXLib for SmartChainXLib.Channel;

    SmartChainXLib.Channel pangolinChannel = SmartChainXLib.Channel(bytes2(0x2b03), 0);

    function sendMessageToPangolin(uint256 deliveryAndDispatchFee, uint32 specVersionOfTargetChain, uint64 callWeight, bytes memory callEncoded) internal {
        bytes memory message = SmartChainXLib.buildMessage(specVersionOfTargetChain, callWeight, callEncoded);
        pangolinChannel.sendMessage(deliveryAndDispatchFee, message);
    }
}