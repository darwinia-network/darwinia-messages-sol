// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ISettingsRegistry {
    function addressOf(bytes32 _propertyName) external view returns (address);
    event ChangeProperty(bytes32 indexed _propertyName, uint256 _type);
}