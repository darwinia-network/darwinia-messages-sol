// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IMessageVerifier {
    function bridgedChainPosition() external view returns(uint32);
    function bridgedLanePosition() external view returns(uint32);
    function thisChainPosition() external view returns(uint32);
    function thisLanePosition() external view returns(uint32);
    function encodeMessageKey(uint64 nonce) external view returns (uint256);
}
