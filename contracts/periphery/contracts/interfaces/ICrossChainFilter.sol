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

pragma solidity ^0.8.0;

/// @title ICrossChainFilter
/// @notice A interface for message layer to filter unsafe message
/// @dev The app layer must implement the interface `ICrossChainFilter`
interface ICrossChainFilter {
    /// @notice Verify the source sender and payload of source chain messages,
    /// Generally, app layer cross-chain messages require validation of sourceAccount
    /// @param bridgedChainPosition The source chain position which send the message
    /// @param bridgedLanePosition The source lane position which send the message
    /// @param sourceAccount The source contract address which send the message
    /// @param payload The calldata which encoded by ABI Encoding
    /// @return Can call target contract if returns true
    function cross_chain_filter(uint32 bridgedChainPosition, uint32 bridgedLanePosition, address sourceAccount, bytes calldata payload) external view returns (bool);
}
