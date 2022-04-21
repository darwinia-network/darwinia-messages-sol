// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
import "./ds-test/test.sol";

import "./Input.sol";
import "./Scale.sol";
import { ScaleStruct, S2SBacking } from "./Scale.struct.sol";
import "./ScaleCodec.sol";
import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract ScaleCodecTest is DSTest {
    using Input for Input.Data;

    function setUp() public {}

    function assertCompactEq(uint256 v, bytes memory e) internal {
        assertEq0(ScaleCodec.encodeUintCompact(v), e);
    }

    function testEncodeUintCompact_SingleByte() public {
        assertCompactEq(0, hex"00");
        assertCompactEq(1, hex"04");
        assertCompactEq(42, hex"a8");
        assertCompactEq(63, hex"fc");
    }

    function testEncodeUintCompact_TwoByte() public {
        assertCompactEq(69, hex"1501");
    }

    function testEncodeUintCompact_FourByte() public {
        assertCompactEq(1073741823, hex"feffffff");
    }

    function testEncodeUintCompact_Big() public {
        assertCompactEq(1073741824, hex"0300000040");
    }

    function testEncodeUnlockFromRemoteCall() public {
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
        S2SBacking.SystemRemarkCall memory call = S2SBacking.SystemRemarkCall(
            hex"0001",
            hex"12345678"
        );

        bytes memory e = hex"00011012345678";
        bytes memory r = S2SBacking.encodeSystemRemarkCall(call);
        assertEq0(r, e);
    }


}
