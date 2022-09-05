// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.7.6;

/// @title A interface for app layer to send cross chain message
/// @author echo
/// @notice The app layer could implement the interface `IOnMessageDelivered` to receive message dispatch result (optionally)
interface IOutboundLane {
    /// @notice Send message over lane.
    /// Submitter could be a contract or just an EOA address.
    /// At the beginning of the launch, submmiter is permission, after the system is stable it will be permissionless.
    /// @param targetContract The target contract address which you would send cross chain message to
    /// @param encoded The calldata which encoded by ABI Encoding `abi.encodePacked(SELECTOR, PARAMS)`
    /// @return Encoded message key
    function send_message(address targetContract, bytes calldata encoded) external payable returns (uint256);
}
