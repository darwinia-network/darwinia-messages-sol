// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

abstract contract SmartChainXApp {
    struct Vars {
        // vars for dispatch call
        address dispatchAddress;
        bytes2 dispatchCallIndex;
        // vars for market fee
        address storageAddress;
        bytes storageKeyForMarketFee;
    }

    struct MessagePayload {
        uint32 specVersionOfTargetChain;
        uint64 callWeight;
        bytes callEncoded;
    }

    Vars vars;

    // Send message over lane.
    function sendMessage(
        bytes4 laneId,
        MessagePayload memory payload
    ) internal {
        uint128 fee = SmartChainXLib.marketFee(
            vars.storageAddress,
            vars.storageKeyForMarketFee
        );

        require(msg.value >= fee, "Not enough fee to pay");

        bytes memory message = SmartChainXLib.buildMessage(
            payload.specVersionOfTargetChain,
            payload.callWeight,
            payload.callEncoded
        );

        SmartChainXLib.sendMessage(
            vars.dispatchAddress,
            vars.dispatchCallIndex,
            laneId,
            msg.value,
            message
        );
    }

    function set(
        Vars memory _vars
    ) internal {
        vars = _vars;
    }
}
