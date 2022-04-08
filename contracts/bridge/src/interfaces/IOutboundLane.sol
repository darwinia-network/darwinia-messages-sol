// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IOutboundLane {
    function send_message(address targetContract, bytes calldata encoded) external payable returns (uint256);
}
