//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.16;

contract Greeter {
  string greeting;

  constructor(string memory _greeting) public{
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    uint uint_test = 12341234;
    bytes32 bytes_test = keccak256("fun(uint256)");
    greeting = _greeting;
  }
}
