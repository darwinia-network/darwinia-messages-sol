// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISubStateStorage {
    function state_storage(bytes calldata key) external view returns (bytes memory);
}
