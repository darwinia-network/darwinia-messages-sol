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
pragma abicoder v2;

import "./BeaconChain.sol";

contract BeaconLightClientUpdate is BeaconChain {
    struct SyncAggregate {
        bytes32[2] sync_committee_bits;
        bytes sync_committee_signature;
    }

    struct FinalizedHeaderUpdate {
        // The beacon block header that is attested to by the sync committee
        BeaconBlockHeader attested_header;

        // Sync committee corresponding to sign attested header
        SyncCommittee signature_sync_committee;

        // The finalized beacon block header attested to by Merkle branch
        BeaconBlockHeader finalized_header;
        bytes32[] finality_branch;

        // Sync committee aggregate signature
        SyncAggregate sync_aggregate;

        // Fork version for the aggregate signature
        bytes4 fork_version;

        // Slot at which the aggregate signature was created (untrusted)
        uint64 signature_slot;
    }

    struct SyncCommitteePeriodUpdate {
        // Next sync committee corresponding to the finalized header
        SyncCommittee next_sync_committee;
        bytes32[] next_sync_committee_branch;
    }
}
