// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

abstract contract SmartChainXApp {
    struct MessagePayload {
        uint32 specVersionOfTargetChain;
        uint64 callWeight;
        bytes callEncoded;
    }

    // The call index of `send_message` on the source chain.
    // The default value `0x3003` is the call index on Crab.
    // https://github.com/darwinia-network/darwinia-bridges-substrate/blob/17a2211dc7a9e2f9ac88857d01a1376a4e559a83/modules/messages/src/lib.rs#L275
    bytes2 sendMessageCallIndexOnSourceChain = 0x3003;

    // Send message over lane.
    function sendMessage(
        bytes4 laneId,
        MessagePayload memory payload,
        uint256 deliveryAndDispatchFee
    ) internal {
        bytes memory message = SmartChainXLib.buildMessage(
            payload.specVersionOfTargetChain,
            payload.callWeight,
            payload.callEncoded
        );

        SmartChainXLib.sendMessage(
            sendMessageCallIndexOnSourceChain,
            laneId,
            deliveryAndDispatchFee,
            message
        );
    }

    function setSendMessageCallIndexOnSourceChain(
        bytes2 _sendMessageCallIndexOnSourceChain
    ) internal {
        sendMessageCallIndexOnSourceChain = _sendMessageCallIndexOnSourceChain;
    }
}
