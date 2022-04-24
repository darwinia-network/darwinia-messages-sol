// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
import "./ds-test/test.sol";

import "./AccountId.sol";
import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract AccountIdTest is DSTest {
    function setUp() public {}

    function testFromAddress() public {
        // pangoro call
        bytes32 r = AccountId.fromAddress(0x6D6F646C64612f6272696e670000000000000000);

        bytes32 e = bytes32(0x64766d3a000000000000006d6f646c64612f6272696e67000000000000000015);
        assertEq(r, e);
    }
}