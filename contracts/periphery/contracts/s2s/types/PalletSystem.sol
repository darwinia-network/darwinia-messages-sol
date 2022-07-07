// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";

library PalletSystem {
    struct RemarkCall {
        bytes2 callIndex;
        bytes remark;
    }

    function encodeRemarkCall(RemarkCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _call.callIndex,
                ScaleCodec.encodeBytes(_call.remark)
            );
    }
}
