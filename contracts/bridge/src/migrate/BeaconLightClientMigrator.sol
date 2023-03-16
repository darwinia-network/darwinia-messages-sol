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

import "../truth/eth/BeaconLightClient.sol";
import "../truth/eth/ExecutionLayer.sol";


interface IEthereumStorageVerifier {
    function changeLightClient(address lightclient) external;
    function changeSetter(address setter) external;
}

contract BeaconLightClientMigrator {
    BeaconLightClient public new_beacon_lc;
    ExecutionLayer public new_execution_layer;

    address public immutable HELIX_DAO;
    address public immutable OLD_BEACON_LC;
    address public immutable ETHEREUM_STORAGE_VERIFIER;
    address public immutable BLS_PRECOMPILE;
    bytes32 public immutable GENESIS_VALIDATORS_ROOT;
    uint64 public immutable CAPELLA_FORK_EPOCH;

    constructor(
        address helix_dao,
        address old_lc,
        address verifier,
        address bls,
        bytes32 genesis_validators_root,
        uint64  capella_for_epoch
    ) {
        HELIX_DAO = helix_dao;
        OLD_BEACON_LC = old_lc;
        ETHEREUM_STORAGE_VERIFIER = verifier;
        BLS_PRECOMPILE = bls;
        GENESIS_VALIDATORS_ROOT = genesis_validators_root;
        CAPELLA_FORK_EPOCH = capella_for_epoch;
    }

    function migrate() public {
        // fetch latest finalized header
        (
            uint64 slot,
            uint64 proposer_index,
            bytes32 parent_root,
            bytes32 state_root,
            bytes32 body_root
        ) = BeaconLightClient(OLD_BEACON_LC).finalized_header();
        // current sync committee period
        uint64 period = slot / 32 / 256;
        // fetch current sync_committee hash
        bytes32 current_sync_committee_hash = BeaconLightClient(OLD_BEACON_LC).sync_committee_roots(period);
        require(current_sync_committee_hash != bytes32(0), "missing");

        // new BeaconLightClient
        new_beacon_lc = new BeaconLightClient(
            BLS_PRECOMPILE,
            slot,
            proposer_index,
            parent_root,
            state_root,
            body_root,
            current_sync_committee_hash,
            GENESIS_VALIDATORS_ROOT
        );
        // new ExecutionLayer
        new_execution_layer = new ExecutionLayer(address(new_beacon_lc), CAPELLA_FORK_EPOCH);
        // change light client
        IEthereumStorageVerifier(ETHEREUM_STORAGE_VERIFIER).changeLightClient(address(new_execution_layer));

        returnSetter();
    }

    function returnSetter() public {
        // return auth
        IEthereumStorageVerifier(ETHEREUM_STORAGE_VERIFIER).changeSetter(HELIX_DAO);
    }
}
