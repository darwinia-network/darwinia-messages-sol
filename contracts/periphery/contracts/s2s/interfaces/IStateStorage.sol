// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IStateStorage {
    function state_storage(bytes memory key) external view returns (bytes memory);
}