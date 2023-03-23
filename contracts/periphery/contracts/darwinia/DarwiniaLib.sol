// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";

library DarwiniaLib {
    function buildXcmTransactMessage(
        bytes2 fromParachain,
        bytes memory call,
        uint64 callWeight,
        uint128 fungible
    ) internal pure returns (bytes memory) {
        // xcm_version: 2
        // instructions:
        //
        //   - instruction: withdraw_asset
        //     assets:
        //       - &ring
        //         id:
        //           concrete:
        //             parents: 01,
        //             interior:
        //               X2:
        //                 - parachain: #{fromParachain}
        //                 - pallet_instance: 5
        //         fun:
        //           fungible: #{fungible}
        //
        //   - instruction: buy_execution
        //     fees: *ring
        //     weight_limit: unlimited
        //
        //   - instruction: transact
        //     origin_type: 1
        //     require_weight_at_most: #{callWeight}
        //     call: #{call}
        //
        bytes memory funEncoded = ScaleCodec.encodeUintCompact(fungible);
        return
            abi.encodePacked(
                // XcmVersion + Instruction Length
                hex"020c",
                // WithdrawAsset
                // --------------------------
                hex"000400010200",
                fromParachain,
                hex"040500",
                funEncoded,
                // BuyExecution
                // --------------------------
                hex"1300010200",
                fromParachain,
                hex"040500",
                funEncoded,
                hex"00", // weight limit
                // Transact
                // --------------------------
                hex"0601",
                ScaleCodec.encodeUintCompact(callWeight),
                ScaleCodec.encodeUintCompact(call.length),
                call
            );
    }
}
