// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

contract MappingTokenAddress {
    address public constant DISPATCH_ENCODER = 0x0000000000000000000000000000000000000018;
    address public constant DISPATCH = 0x0000000000000000000000000000000000000019;
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // This system account is derived from the dvm pallet id `dar/dvmp`,
    // and it has no private key, it comes from internal transaction in dvm.
    address public constant SYSTEM_ACCOUNT = 0x6D6F646C6461722f64766D700000000000000000;
}
