// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

interface IMessageCommitment {
    function lanePosition() external view returns (uint256);
    function chainPosition() external view returns (uint256);
    function commitment() external view returns (bytes32)
}
