// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./CommonTypes.sol";

library PalletBalances {
    struct TransferCall {
        bytes2 callIndex;
        CommonTypes.EnumItemWithAccountId dest;
        uint128 value;
    }

    function encodeTransferCall(TransferCall memory _call) internal pure returns (bytes memory) {
        bytes memory destEncoded = CommonTypes.encodeEnumItemWithAccountId(_call.dest);
        bytes memory valueEncoded = ScaleCodec.encodeUintCompact(_call.value);
        return abi.encodePacked(
            _call.callIndex, 
            destEncoded, 
            valueEncoded
        );
    }
}