// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
import "./ds-test/test.sol";

import "./Input.sol";
import "./Scale.sol";
import { Types, S2SBacking, System, Balances } from "./Scale.types.sol";
import "./ScaleCodec.sol";
import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract ScaleTypesTest is DSTest {
    using Input for Input.Data;

    function setUp() public {}

    function testEncodeS2SBackingUnlockFromRemoteCall() public {
        // pangoro call
        S2SBacking.UnlockFromRemoteCall memory call = S2SBacking.UnlockFromRemoteCall(
            hex"1402",
            0x6D6F646C64612f6272696e670000000000000000,
            100000,
            hex"d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d"
        );

        bytes memory e = hex"14026d6f646c64612f6272696e670000000000000000a08601000000000000000000000000000000000000000000000000000000000080d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d";
        bytes memory r = S2SBacking.encodeUnlockFromRemoteCall(call);
        assertEq0(r, e);
    }

    function testEncodeSystemRemarkCall() public {
        // pangoro call
        System.RemarkCall memory call = System.RemarkCall(
            hex"0001",
            hex"12345678"
        );

        bytes memory e = hex"00011012345678";
        bytes memory r = System.encodeRemarkCall(call);
        assertEq0(r, e);
    }

    function testEncodeBalancesTransferCall() public {
        // pangoro call
        Balances.TransferCall memory call = Balances.TransferCall(
            hex"0400",
            Types.EnumItemWithAccountId(
                0,
                0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d
            ),
            666
        );

        bytes memory e = hex"040000d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d690a";
        bytes memory r = Balances.encodeTransferCall(call);
        assertEq0(r, e);
    }

    function testEncodeMessage() public {
        // the remote call of pangoro
        S2SBacking.UnlockFromRemoteCall memory call = S2SBacking.UnlockFromRemoteCall(
            hex"1402",
            0x6D6F646C64612f6272696e670000000000000000,
            100000,
            hex"d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d"
        );
        bytes memory callEncoded = S2SBacking.encodeUnlockFromRemoteCall(call);

        // the origin for the remote call        
        Types.EnumItemWithAccountId memory origin = Types.EnumItemWithAccountId(
            2,
            0x64766d3a00000000000000d2c7008400f54aa70af01cf8c747a4473246593ea2
        );


        // the message encoding
        Types.EnumItemWithNull memory dispatchFeePayment = Types.EnumItemWithNull(0);
        Types.Message memory msg1 = Types.Message(
            28080,
            2654000000,
            origin,
            dispatchFeePayment,
            callEncoded
        );
        bytes memory r = Types.encodeMessage(msg1);


        bytes memory e = hex"b06d000080d3309e000000000264766d3a00000000000000d2c7008400f54aa70af01cf8c747a4473246593ea2005d0114026d6f646c64612f6272696e670000000000000000a08601000000000000000000000000000000000000000000000000000000000080d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d";
        assertEq0(r, e);
    }

}
