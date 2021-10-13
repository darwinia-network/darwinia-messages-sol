// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

interface IOutboundLane {
    function sendMessage(address targetContract, bytes calldata payload) external;
}
