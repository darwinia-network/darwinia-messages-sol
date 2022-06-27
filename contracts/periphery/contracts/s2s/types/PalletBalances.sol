// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./CommonTypes.sol";

library PalletBalances {
    struct TransferCall {
        bytes2 callIndex;
        CommonTypes.EnumItemWithAccountId dest;
        uint128 value;
    }

    function encodeTransferCall(TransferCall memory call) internal pure returns (bytes memory) {
        bytes memory destEncoded = CommonTypes.encodeEnumItemWithAccountId(call.dest);
        bytes memory valueEncoded = ScaleCodec.encodeUintCompact(call.value);
        return abi.encodePacked(
            call.callIndex, 
            destEncoded, 
            valueEncoded
        );
    }
}