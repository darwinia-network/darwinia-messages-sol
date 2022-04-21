// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
import "./ds-test/test.sol";

import "./Input.sol";
import "./Scale.sol";
import { ScaleStruct } from "./Scale.struct.sol";
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
}
