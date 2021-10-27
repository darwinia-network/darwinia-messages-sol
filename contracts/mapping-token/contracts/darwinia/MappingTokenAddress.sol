// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

contract MappingTokenAddress {
    address public constant DISPATCH_ENCODER = 0x0000000000000000000000000000000000000018;
    address public constant DISPATCH = 0x0000000000000000000000000000000000000019;

    // This system account is derived from the dvm pallet id `dar/dvmp`,
    // and it has no private key, it comes from internal transaction in dvm.
    address public constant SYSTEM_ACCOUNT = 0x6D6F646C6461722f64766D700000000000000000;
}
