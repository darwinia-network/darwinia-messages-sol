// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
import "./ds-test/test.sol";

import "./Bytes.sol";
import "./Input.sol";
import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract InputTest is DSTest {
    using Bytes for bytes;
    using Input for Input.Data;

    function setUp() public {}

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

    function testToBytes32() public logs_gas{
        Input.Data memory data = Input.from(hex"000015eaf80e3066655d1638aa316fe417d6998efbc383204099c00d5429c8d06456");
        bytes32 res = data.decodeBytes32();
        assertEq32(res, bytes32(hex'000015eaf80e3066655d1638aa316fe417d6998efbc383204099c00d5429c8d0'));
    }

    function testToBytesN() public logs_gas{
        Input.Data memory data = Input.from(hex"000015eaf80e3066655d1638aa316fe417d6998efbc383204099c00d5429c8d06456");
        bytes memory res = data.decodeBytesN(32);
        res.toBytes32();
        assertEq32(res.toBytes32(), bytes32(hex'000015eaf80e3066655d1638aa316fe417d6998efbc383204099c00d5429c8d0'));
    }

    function testToBytes32Revert() public logs_gas{
        Input.Data memory data = Input.from(hex"0000");
        data.decodeBytes32();
    }
}
