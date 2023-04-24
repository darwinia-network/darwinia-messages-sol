// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMessageEndpoint {
    /// Remote call the `execute` function of the target chain.
    ///
    /// @param specVersion The spec version of the target chain.
    /// @param callReceiver The receiver of the call.
    /// @param callPayload The payload of the call.
    /// @param gasLimit It is for `execute(callReceiver, callPayload)` call.
    function remoteExecute(
        uint32 specVersion,
        address callReceiver,
        bytes calldata callPayload,
        uint256 gasLimit
    ) external payable returns (uint256);

    function fee() external view returns (uint128);
}
