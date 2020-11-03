//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.16;

import "hardhat/console.sol";


contract Greeter {
  string greeting;

  constructor(string memory _greeting) public{
    console.log("Deploying a Greeter with greeting:", _greeting);
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    uint uint_test = 12341234;
    bytes32 bytes_test = keccak256("fun(uint256)");
    console.logBytes32(bytes_test);
    greeting = _greeting;
  }
}
