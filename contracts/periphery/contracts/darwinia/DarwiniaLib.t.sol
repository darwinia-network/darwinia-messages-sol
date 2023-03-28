// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../ds-test/test.sol";
import "./DarwiniaLib.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract DarwiniaLibTest is DSTest {
    function setUp() public {}

    function testXcmTransactOnParachain() public {
        bytes memory data = DarwiniaLib.buildXcmTransactMessage(
            0xe520, // from parachain id, crab paraId: 0xe520 == 2105
            hex"0a070c313233", // call
            5000000000, // call weight
            20000000000000000000 // fungible
        );
        console.logBytes(data);
        assertEq0(
            data,
            hex"020c000400010200e520040500170000d01309468e15011300010200e520040500170000d01309468e15010006010700f2052a01180a070c313233"
        );
    }
}
