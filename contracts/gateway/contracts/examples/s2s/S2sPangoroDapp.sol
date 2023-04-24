// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/IMessageReceiver.sol";

contract S2sPangoroDapp is IMessageReceiver {
    uint256 public sum;

    function recv(address _fromDappAddress, bytes calldata _message) external {
        uint256 value = abi.decode(_message, (uint256));
        sum = sum + value;
    }
}
