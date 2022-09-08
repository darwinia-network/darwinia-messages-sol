// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Callee {
    uint256 public sum;

    function add(uint256 _value) external {
        sum = sum + _value;
    }
}