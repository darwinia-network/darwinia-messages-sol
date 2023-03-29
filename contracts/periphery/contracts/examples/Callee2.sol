// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ICrossChainFilter.sol";

contract Callee2 is ICrossChainFilter {
    uint256 public sum;

    function add(uint256 _value) external {
        sum = sum + _value;
    }

    function cross_chain_filter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata payload
    ) external view returns (bool) {
        return true;
    }
}
