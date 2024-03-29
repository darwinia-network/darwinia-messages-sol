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

import "../spec/MessageProof.sol";

/// @title IMessageCommitter
/// @notice A interface for message committer
interface IMessageCommitter {
    /// @notice Return leave count
    function count() external view returns (uint256);
    /// @notice Return pos leave proof
    /// @param pos Which position leave to be prove
    /// @return MessageSingleProof message single proof of the leave
    function proof(uint256 pos) external view returns (MessageSingleProof memory);
    /// @notice Return committer address of positon
    /// @param pos Which positon of all leaves
    /// @return committer address of the positon
    function leaveOf(uint256 pos) external view returns (address);
    /// @notice Return message commitment of the committer
    /// @return commitment hash
    function commitment() external view returns (bytes32);

    /// @notice this chain position
    function THIS_CHAIN_POSITION() external view returns (uint32);
    /// @notice bridged chain position
    function BRIDGED_CHAIN_POSITION() external view returns (uint32);
}
