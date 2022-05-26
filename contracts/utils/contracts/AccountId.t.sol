// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
import "./ds-test/test.sol";

import "./AccountId.sol";
import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract AccountIdTest is DSTest {
    function setUp() public {}

    function testFromAddress() public {
        bytes32 r = AccountId.fromAddress(0x6D6F646C64612f6272696e670000000000000000);
        bytes32 e = bytes32(0x64766d3a000000000000006d6f646c64612f6272696e67000000000000000015);
        assertEq(r, e);
    }

    function testDeriveEthereumAddressFromDvmAccountId() public {
        address e = AccountId.deriveEthereumAddress(bytes32(0x64766d3a000000000000006be02d1d3665660d22ff9624b7be0551ee1ac91bd2));
        address r = 0x6Be02d1d3665660d22FF9624b7BE0551ee1Ac91b;

        assertEq(r, e);
    }

    function testDeriveEthereumAddressFromNormalAccountId() public {
        address e = AccountId.deriveEthereumAddress(bytes32(0x02497755176da60a69586af4c5ea5f5de218eb84011677722646b602eb2d240e));
        address r = 0x02497755176dA60A69586aF4C5ea5F5De218eB84;

        assertEq(r, e); 
    }
}