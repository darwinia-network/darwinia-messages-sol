// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

interface IOutboundLane {
    function send_message(address targetContract, bytes calldata encoded) external payable returns (uint64);
}
