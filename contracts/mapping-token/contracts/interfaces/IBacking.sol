// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IBacking {
    function unlockFromRemote(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address mappingTokenFactory,
        address originalToken,
        address recipient,
        uint256 amount) external;
}
