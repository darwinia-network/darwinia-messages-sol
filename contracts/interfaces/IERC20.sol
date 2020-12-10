pragma solidity >=0.5.0 <0.6.0;

contract IERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function mint(address _to, uint256 _value) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
}
