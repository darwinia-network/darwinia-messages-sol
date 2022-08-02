// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract WCKTONMigrator {
     IERC20 public immutable old_wckton;
     IERC20 public immutable new_wckton;

     constructor(address _old, address _new) {
         old_wckton = IERC20(_old);
         new_wckton = IERC20(_new);
     }

     function migrate() external {
         uint balance = old_wckton.balanceOf(msg.sender);
         old_wckton.transferFrom(msg.sender, address(this), balance);
         new_wckton.transferFrom(address(this), msg.sender, balance);
     }
}
