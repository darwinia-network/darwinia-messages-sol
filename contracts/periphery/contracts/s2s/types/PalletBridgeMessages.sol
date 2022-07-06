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

    function encodeSendMessageCall(SendMessageCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _call.callIndex,
                _call.lineId,
                _call.message,
                ScaleCodec.encode128(_call.deliveryAndDispatchFee)
            );
    }
}
