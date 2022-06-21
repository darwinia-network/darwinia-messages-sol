// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./CommonTypes.sol";

library PalletBridgeMessages {
    struct SendMessageCall {
        bytes2 callIndex;
        bytes4 lineId;
        bytes message;
        uint128 deliveryAndDispatchFee;
    }

    function encodeSendMessageCall(SendMessageCall memory call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                call.callIndex,
                call.lineId,
                call.message,
                ScaleCodec.encode128(call.deliveryAndDispatchFee)
            );
    }
}
