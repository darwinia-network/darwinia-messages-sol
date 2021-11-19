// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

interface IMessageCommitment {
    function lanePosition() external view returns (uint32);
    function thisChainPosition() external view returns (uint32);
    function bridgedChainPosition() external view returns (uint32);
    function commitment() external view returns (bytes32);
}
