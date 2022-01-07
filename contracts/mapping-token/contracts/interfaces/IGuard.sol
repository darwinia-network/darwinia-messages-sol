// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IGuard {
  function deposit(address token, address recipient, uint256 amount) external;
}

