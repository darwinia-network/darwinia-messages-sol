// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// On Pangolin
contract Add {
    uint256 public sum;

    function add(uint256 _value) external {
        sum = sum + _value;
    }
}
