// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../ds-test/test.sol";
import "./DarwiniaLib.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract DarwiniaLibTest is DSTest {
    function setUp() public {}

    function testBuildCallTransactThroughSigned() public {
        bytes memory data = DarwiniaLib.buildCall_TransactThroughSigned(
            0x2d06, // callIndex
            0x591f, // astar paraid
            0xe520, // dariwnia paraid
            hex"0a070c313233", // call
            0 // weight
        );
        assertEq0(data, hex"2d0600010100591f0100010200e520040501000084e2506ce67c0000000000000000180a070c31323300ca9a3b000000000100f2052a01000000");
    }
}
