// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../ds-test/test.sol";
import "./DarwiniaLib.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract DarwiniaLibTest is DSTest {
    function setUp() public {}

    function testXcmTransactOnParachain() public {
        bytes memory data = DarwiniaLib.xcmTransactOnParachain(
            0xe520, // from
            hex"0a070c313233", // call
            6000000000 // weight
        );
        assertEq0(data, hex"020c000400010200e520040500130000e8890423c78a1300010200e520040500130000e8890423c78a0006010700bca06501180a070c313233");
    }
}
