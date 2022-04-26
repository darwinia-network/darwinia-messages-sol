// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

/// @title A interface for app layer to send cross chain message
/// @author echo
/// @notice The app layer could implement the interface `IOnMessageDelivered` to receive message dispatch result (optionally)
interface IOutboundLane {
    /// @notice Send message over lane.
    /// Submitter could be a contract or just an EOA address.
    /// At the beginning of the launch, submmiter is permission, after the system is stable it will be permissionless.
    /// @param targetContract The target contract address which you would send cross chain message to
    /// @param encoded The calldata which encoded by ABI Encoding `abi.encodePacked(SELECTOR, PARAMS)`
    function send_message(address targetContract, bytes calldata encoded) external payable returns (uint256);
}
