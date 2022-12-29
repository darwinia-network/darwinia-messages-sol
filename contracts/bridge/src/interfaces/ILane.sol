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

/// @title ILane
/// @notice A interface for user to fetch lane info
interface ILane {
    /// @dev Return lane info
    /// @return this_chain_pos This chain position
    /// @return this_lane_pos This lane position
    /// @return bridged_chain_pos Bridged chain pos
    /// @return bridged_lane_pos Bridged lane pos
    function getLaneInfo() external view returns (uint32 this_chain_pos, uint32 this_lane_pos, uint32 bridged_chain_pos, uint32 bridged_lane_pos);
}
