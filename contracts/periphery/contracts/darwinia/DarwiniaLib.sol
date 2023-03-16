// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";

library DarwiniaLib {
    function xcmTransactOnParachain(
        bytes2 fromParachain, 
        bytes memory call, 
        uint64 weight
    ) internal pure returns (bytes memory) {
        // xcm_version: 2
        // instructions:
        //   - type: withdraw_asset
        //     assets:
        //       - &ring
        //         id:
        //           concrete:
        //             parents: 01,
        //             interior:
        //               X2:
        //                 - parachain: 2105
        //                 - pallet_instance: 5
        //         fun:
        //           fungible: '0x130000e8890423c78a'
        //   - type: buy_execution
        //     fees: *ring
        //     weight_limit: unlimited
        //   - type: transact
        //     origin_type: 1
        //     require_weight_at_most: '0x0700bca06501'
        //     call: '0x240a070c313233'
        return abi.encodePacked(
            // XcmVersion, Instruction Length
            hex"020c",
            // WithdrawAsset
            hex"000400010200", fromParachain, hex"040500130000e8890423c78a",
            // BuyExecution
            hex"1300010200", fromParachain, hex"040500130000e8890423c78a00",
            // Transact
            hex"0601",
            ScaleCodec.encodeUintCompact(weight),
            ScaleCodec.encodeUintCompact(call.length),
            call
        );
    }
}
