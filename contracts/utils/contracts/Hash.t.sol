// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
import "./ds-test/test.sol";

import "./Hash.sol";
import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract HashTest is DSTest {
    function setUp() public {}

    function testBlake2b128() public {
        bytes16 r = Hash.blake2b128(hex"00000000");
        bytes16 e = bytes16(0x11d2df4e979aa105cf552e9544ebd2b5);
        assertEq(r, e);
    }

    function testBlake2b128Concat() public {
        bytes memory r = Hash.blake2b128Concat(hex"00000000");
        bytes memory e = hex"11d2df4e979aa105cf552e9544ebd2b500000000";
        assertEq0(r, e);
    }
}