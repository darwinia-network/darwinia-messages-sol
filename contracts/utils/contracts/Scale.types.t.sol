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
            0x1200000000000000000000000000000000000012,
            7123,
            hex"1234"
        );

        bytes memory e = hex"14021200000000000000000000000000000000000012d31b000000000000000000000000000000000000000000000000000000000000081234";
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
            Types.EnumItemAccountId32(
                0,
                0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d
            ),
            666
        );

        bytes memory e = hex"040000d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d690a";
        bytes memory r = Balances.encodeTransferCall(call);
        assertEq0(r, e);
    }

}
