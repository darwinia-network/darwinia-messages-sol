// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";

library DarwiniaLib {
    // Build the `XcmTransactor`.`TransactThroughSigned` call
    function buildCall_TransactThroughSigned(
        bytes2 callIndex,
        bytes2 targetParaId, 
        bytes2 darwiniaParaId, 
        bytes memory call, 
        uint64 weight
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            callIndex,

            // DEST: V2(01, X1(Parachain(ParaId)))
            //       00(01, 01(       00(  e520)))
            hex"00010100", targetParaId, 

            // FEE: 
            // AsMultiLocation(V2(01, X2(Parachain(ParaId), PalletInstance(05))), feeAmount)
            //                 01(00(01, 02(       00(  e520),             04(05))), ...)
            hex"0100010200", darwiniaParaId, hex"0405",
            hex"01000084e2506ce67c0000000000000000", // TODO: fix

            // CALL
            ScaleCodec.encodeUintCompact(call.length), // call bytes length prefix
            call,

            // WEIGHTINFO 
            // TODO: fix
            hex"00ca9a3b00000000", // transactrequiredweightatmost
            hex"0100f2052a01000000" // overallweight
        );
    }
}
