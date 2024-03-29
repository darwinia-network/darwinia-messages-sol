// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ds-test/test.sol";
import "./MessageLib.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract MessageLibTest is DSTest {
    function setUp() public {}

    function testDeriveAccountId() public {
        bytes4 srcChainId = 0x00000000;
        bytes32 accountId = 0x64766d3a0000000000000061dc46385a09e7ed7688abe6f66bf3d8653618fd6c;
        bytes32 r = MessageLib.deriveAccountId(srcChainId, accountId);

        bytes32 e = 0x95804eb66d1944a85d73fba99465cb33c715d5169471edd9d7d6fbb022ceaa28;
        assertTrue(r == e);
    }
}
