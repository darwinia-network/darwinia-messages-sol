// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IBacking {
    function unlockFromRemote(
        address mappingTokenFactory,
        address originalToken,
        address recipient,
        uint256 amount) external;
}
