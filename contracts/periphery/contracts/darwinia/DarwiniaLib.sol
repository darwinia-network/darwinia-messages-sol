// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";

library DarwiniaLib {
    function xcmTransactOnParachain(
        bytes2 fromParachain, 
        bytes memory call, 
        uint64 weight
    ) internal pure returns (bytes memory) {
        // 02(                                            // XcmVersion::V2(Vec<Instruction>)
        //   [                                            // 0c: len
        //
        //     00(                                        // Instruction::WithdrawAsset(Vec<MultiAsset>)
        //       [                                        // 04: len 
        //         {                                      // MultiAsset
        //           id: 00(                              // AssetId::Concrete(MultiLocation)
        //             {                                  // MultiLocation
        //               parents: 01,
        //               interior: 02(                    // Junctions::X2(Junction, Junction)
        //                 00(2105),                      // Junction::Parachain(CompactU32)
        //                 04(5)                          // Junction::PalletInstance(u8)
        //               )
        //             }
        //           ), 
        //           fun: 00(130000e8890423c78a)        // Fungibility::Fungible(u128)
        //         }
        //       ]
        //     ),
        //
        //     13(                                        // Instruction::BuyExecution(fees: MultiAsset, weightLimit: WeightLimit)
        //       {
        //         fees: {
        //           id: 00(
        //             parents: 01,
        //             interior: 02(
        //               00(2105),
        //               04(5)
        //             )
        //           ),
        //           fun: 00(10000000000000000000)
        //         },
        //         weightLimit: 00                        // WeightLimit::Unlimited
        //       }
        //     )
        //
        //     06(                                        // Instruction::Transact(originType, requireWeightAtMost, call)
        //       {
        //         originType: 01,
        //         requireWeightAtMost: 0700bca06501,     // 6000000000: Compact<u64>
        //         call: 18 0a070c313233                  // Bytes
        //       }
        //     )
        //
        //   ]
        // )
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
