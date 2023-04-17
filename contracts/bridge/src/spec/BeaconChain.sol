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

import "./MerkleProof.sol";
import "../utils/ScaleCodec.sol";

/// @title BeaconChain
/// @notice Beacon chain specification
contract BeaconChain is MerkleProof {
    /// @notice bls public key length
    uint64 constant internal BLSPUBLICKEY_LENGTH = 48;
    /// @notice bls signature length
    uint64 constant internal BLSSIGNATURE_LENGTH = 96;
    /// @notice sync committee size
    uint64 constant internal SYNC_COMMITTEE_SIZE = 512;

    /// @notice Fork data
    /// @param current_version Current verison
    /// @param genesis_validators_root Genesis validators root
    struct ForkData {
        bytes4 current_version;
        bytes32 genesis_validators_root;
    }

    /// @notice Signing data
    /// @param object_root Root of signing object
    /// @param domain Domain
    struct SigningData {
        bytes32 object_root;
        bytes32 domain;
    }

    /// @notice Sync committee
    /// @param pubkeys Pubkeys of sync committee
    /// @param aggregate_pubkey Aggregate pubkey of sync committee
    struct SyncCommittee {
        bytes[SYNC_COMMITTEE_SIZE] pubkeys;
        bytes aggregate_pubkey;
    }

    /// @notice Beacon block header
    /// @param slot Slot
    /// @param proposer_index Index of proposer
    /// @param parent_root Parent root hash
    /// @param state_root State root hash
    /// @param body_root Body root hash
    struct BeaconBlockHeader {
        uint64 slot;
        uint64 proposer_index;
        bytes32 parent_root;
        bytes32 state_root;
        bytes32 body_root;
    }


    /// @notice Light client header
    /// @param beacon Beacon block header
    /// @param execution Execution payload header corresponding to `beacon.body_root` [New in Capella]
    /// @param execution_branch Execution payload header proof corresponding to `beacon.body_root` [New in Capella]
    struct LightClientHeader {
        BeaconBlockHeader beacon;
        ExecutionPayloadHeader execution;
        bytes32[] execution_branch;
    }

    /// @notice Execution payload header in Capella
    /// @param parent_hash Parent hash
    /// @param fee_recipient Beneficiary
    /// @param state_root State root
    /// @param receipts_root Receipts root
    /// @param logs_bloom Logs bloom
    /// @param prev_randao Difficulty
    /// @param block_number Number
    /// @param gas_limit Gas limit
    /// @param gas_used Gas used
    /// @param timestamp Timestamp
    /// @param extra_data Extra data
    /// @param base_fee_per_gas Base fee per gas
    /// @param block_hash Hash of execution block
    /// @param transactions_root Root of transactions
    /// @param withdrawals_root Root of withdrawals [New in Capella]
    struct ExecutionPayloadHeader {
        bytes32 parent_hash;
        address fee_recipient;
        bytes32 state_root;
        bytes32 receipts_root;
        bytes32 logs_bloom;
        bytes32 prev_randao;
        uint64 block_number;
        uint64 gas_limit;
        uint64 gas_used;
        uint64 timestamp;
        bytes32 extra_data;
        uint256 base_fee_per_gas;
        bytes32 block_hash;
        bytes32 transactions_root;
        bytes32 withdrawals_root;
    }

    /// @notice Return the signing root for the corresponding signing data.
    function compute_signing_root(BeaconBlockHeader memory beacon_header, bytes32 domain) internal pure returns (bytes32){
        return hash_tree_root(SigningData({
                object_root: hash_tree_root(beacon_header),
                domain: domain
            })
        );
    }

    /// @notice Return the 32-byte fork data root for the ``current_version`` and ``genesis_validators_root``.
    /// This is used primarily in signature domains to avoid collisions across forks/chains.
    function compute_fork_data_root(bytes4 current_version, bytes32 genesis_validators_root) internal pure returns (bytes32){
        return hash_tree_root(ForkData({
                current_version: current_version,
                genesis_validators_root: genesis_validators_root
            })
        );
    }

    /// @notice Return the domain for the ``domain_type`` and ``fork_version``.
    function compute_domain(bytes4 domain_type, bytes4 fork_version, bytes32 genesis_validators_root) internal pure returns (bytes32){
        bytes32 fork_data_root = compute_fork_data_root(fork_version, genesis_validators_root);
        return bytes32(domain_type) | fork_data_root >> 32;
    }

    /// @notice Return hash tree root of fork data
    function hash_tree_root(ForkData memory fork_data) internal pure returns (bytes32) {
        return hash_node(bytes32(fork_data.current_version), fork_data.genesis_validators_root);
    }

    /// @notice Return hash tree root of signing data
    function hash_tree_root(SigningData memory signing_data) internal pure returns (bytes32) {
        return hash_node(signing_data.object_root, signing_data.domain);
    }

    /// @notice Return hash tree root of sync committee
    function hash_tree_root(SyncCommittee memory sync_committee) internal pure returns (bytes32) {
        bytes32[] memory pubkeys_leaves = new bytes32[](SYNC_COMMITTEE_SIZE);
        for (uint i = 0; i < SYNC_COMMITTEE_SIZE; ++i) {
            bytes memory key = sync_committee.pubkeys[i];
            require(key.length == BLSPUBLICKEY_LENGTH, "!key");
            pubkeys_leaves[i] = hash(abi.encodePacked(key, bytes16(0)));
        }
        bytes32 pubkeys_root = merkle_root(pubkeys_leaves);

        require(sync_committee.aggregate_pubkey.length == BLSPUBLICKEY_LENGTH, "!agg_key");
        bytes32 aggregate_pubkey_root = hash(abi.encodePacked(sync_committee.aggregate_pubkey, bytes16(0)));

        return hash_node(pubkeys_root, aggregate_pubkey_root);
    }

    /// @notice Return hash tree root of beacon block header
    function hash_tree_root(BeaconBlockHeader memory beacon_header) internal pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](5);
        leaves[0] = bytes32(to_little_endian_64(beacon_header.slot));
        leaves[1] = bytes32(to_little_endian_64(beacon_header.proposer_index));
        leaves[2] = beacon_header.parent_root;
        leaves[3] = beacon_header.state_root;
        leaves[4] = beacon_header.body_root;
        return merkle_root(leaves);
    }

    /// @notice Return hash tree root of execution payload in Capella
    function hash_tree_root(ExecutionPayloadHeader memory execution_payload) internal pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](15);
        leaves[0]  = execution_payload.parent_hash;
        leaves[1]  = bytes32(bytes20(execution_payload.fee_recipient));
        leaves[2]  = execution_payload.state_root;
        leaves[3]  = execution_payload.receipts_root;
        leaves[4]  = execution_payload.logs_bloom;
        leaves[5]  = execution_payload.prev_randao;
        leaves[6]  = bytes32(to_little_endian_64(execution_payload.block_number));
        leaves[7]  = bytes32(to_little_endian_64(execution_payload.gas_limit));
        leaves[8]  = bytes32(to_little_endian_64(execution_payload.gas_used));
        leaves[9]  = bytes32(to_little_endian_64(execution_payload.timestamp));
        leaves[10] = execution_payload.extra_data;
        leaves[11] = to_little_endian_256(execution_payload.base_fee_per_gas);
        leaves[12] = execution_payload.block_hash;
        leaves[13] = execution_payload.transactions_root;
        leaves[14] = execution_payload.withdrawals_root;
        return merkle_root(leaves);
    }

    /// @notice Return little endian of uint64
    function to_little_endian_64(uint64 value) internal pure returns (bytes8) {
        return ScaleCodec.encode64(value);
    }

    /// @notice Return little endian of uint256
    function to_little_endian_256(uint256 value) internal pure returns (bytes32) {
        return ScaleCodec.encode256(value);
    }
}
