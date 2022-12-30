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

pragma solidity 0.8.17;

/// @title IVerifier
/// @notice A interface for message layer to verify the correctness of the lane hash
interface IVerifier {
    /// @notice Verify outlane data hash using message/storage proof
    /// @param outlane_data_hash The bridged outlane data hash to be verify
    /// @param outlane_id The bridged outlen id
    /// @param encoded_proof Message/storage abi-encoded proof
    /// @return the verify result
    function verify_messages_proof(
        bytes32 outlane_data_hash,
        uint256 outlane_id,
        bytes calldata encoded_proof
    ) external view returns (bool);

    /// @notice Verify inlane data hash using message/storage proof
    /// @param inlane_data_hash The bridged inlane data hash to be verify
    /// @param inlane_id The bridged inlane id
    /// @param encoded_proof Message/storage abi-encoded proof
    /// @return the verify result
    function verify_messages_delivery_proof(
        bytes32 inlane_data_hash,
        uint256 inlane_id,
        bytes calldata encoded_proof
    ) external view returns (bool);
}
