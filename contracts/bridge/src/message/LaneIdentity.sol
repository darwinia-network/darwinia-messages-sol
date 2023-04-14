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

/// @title LaneIdentity
/// @notice The identity of lane.
abstract contract LaneIdentity {
    function encodeMessageKey(uint64 nonce) public view virtual returns (uint256);

    /// @dev Indentify slot
    Slot0 internal slot0;

    struct Slot0 {
        // nonce place holder
        uint64 nonce_placeholder;
        // Bridged lane position of the leaf in the `lane_message_merkle_tree`, index starting with 0
        uint32 bridged_lane_pos;
        // Bridged chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
        uint32 bridged_chain_pos;
        // This lane position of the leaf in the `lane_message_merkle_tree`, index starting with 0
        uint32 this_lane_pos;
        // This chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
        uint32 this_chain_pos;
    }

    constructor(uint256 _laneId) {
        assembly ("memory-safe") {
            sstore(slot0.slot, _laneId)
        }
    }

    function getLaneInfo() external view returns (uint32,uint32,uint32,uint32) {
        Slot0 memory _slot0 = slot0;
        return (
           _slot0.this_chain_pos,
           _slot0.this_lane_pos,
           _slot0.bridged_chain_pos,
           _slot0.bridged_lane_pos
       );
    }

    function getLaneId() public view returns (uint256 id) {
        assembly ("memory-safe") {
          id := sload(slot0.slot)
        }
    }
}
