// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./CommonTypes.sol";

library PalletBridgeMessages {
    struct SendMessageCall {
        bytes2 callIndex; // pallet index and call func index
        bytes4 laneId;
        bytes message;
        uint128 deliveryAndDispatchFee;
    }

    function encodeSendMessageCall(SendMessageCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _call.callIndex,
                _call.laneId,
                _call.message,
                ScaleCodec.encode128(_call.deliveryAndDispatchFee)
            );
    }
}
