// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

abstract contract CrabSmartChainXApp {
    using SmartChainXLib for SmartChainXLib.Channel;

    SmartChainXLib.Channel darwiniaChannel = SmartChainXLib.Channel(bytes2(0x3003), 0);

    function sendMessageToDarwinia(uint256 deliveryAndDispatchFee, uint32 specVersionOfTargetChain, uint64 callWeight, bytes memory callEncoded) internal {
        bytes memory message = SmartChainXLib.buildMessage(specVersionOfTargetChain, callWeight, callEncoded);
        darwiniaChannel.sendMessage(deliveryAndDispatchFee, message);
    }
}