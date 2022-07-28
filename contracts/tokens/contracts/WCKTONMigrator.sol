pragma solidity 0.8.15;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract WCKTONMigrator {
     IERC20 public immutable old_wckton;
     IERC20 public immutable new_wckton;

     constructor(address _old, address _new) public {
        old_wckton = IERC20(_old);
        new_wckton = IERC20(_new);
     }

     receive() external payable {}

     function migrate() external payable {
         uint balance = IERC20(old_wckton).balanceOf(msg.sender);
         IERC20(old_wckton).transferFrom(msg.sender, address(this), balance);
         IERC20(new_wckton).transferFrom(address(this), msg.sender, balance);
     }
}
