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

import "./BeaconChain.sol";

/// @title BeaconLightClientUpdate
/// @notice Beacon light client update specification
contract BeaconLightClientUpdate is BeaconChain {
    /// @notice Sync aggregate
    /// @param sync_committee_bits Sync committee bits
    /// @param sync_committee_signature Sync committee signature
    struct SyncAggregate {
        bytes32[2] sync_committee_bits;
        bytes sync_committee_signature;
    }

    /// @notice Finalized header update
    /// @param attested_header Header attested to by the sync committee
    /// @param signature_sync_committee  Sync committee corresponding to sign attested header
    /// @param finalized_header The finalized beacon block header
    /// @param finality_branch Finalized header proof corresponding to `attested_header.state_root`
    /// @param sync_aggregate Sync committee aggregate signature
    /// @param fork_version Fork version for the aggregate signature
    /// @param signature_slot Slot at which the aggregate signature was created (untrusted)
    struct FinalizedHeaderUpdate {
        LightClientHeader attested_header;
        SyncCommittee signature_sync_committee;
        LightClientHeader finalized_header;
        bytes32[] finality_branch;
        SyncAggregate sync_aggregate;
        bytes4 fork_version;
        uint64 signature_slot;
    }

    /// @notice Sync committee period update
    /// @param next_sync_committee Next sync committee
    /// @param next_sync_committee_branch Next sync committee corresponding to `attested_header.state_root`
    struct SyncCommitteePeriodUpdate {
        SyncCommittee next_sync_committee;
        bytes32[] next_sync_committee_branch;
    }
}
