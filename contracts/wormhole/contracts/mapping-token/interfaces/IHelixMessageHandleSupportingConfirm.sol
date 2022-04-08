// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IHelixMessageHandle.sol";

interface IHelixMessageHandleSupportingConfirm is IHelixMessageHandle {
    function latestRecvMessageId() external view returns (uint256);
}
