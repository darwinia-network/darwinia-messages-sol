// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../test.sol";
import "../../mock/MockBLS.sol";
import "../../spec/SyncCommittee.t.sol";
import "../../../truth/eth/BeaconLightClient.sol";

contract BeaconLightClientTest is DSTest, SyncCommitteePreset {

    bytes32 constant CURRENT_SYNC_COMMITTEE_ROOT = 0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7;
    bytes32 constant GENESIS_VALIDATORS_ROOT = 0x32251a5a748672e3acb1e574ec27caf3b6be68d581c44c402eb166d71a89808e;
    bytes32 constant LATEST_EXECUTION_PAYLOAD_STATE_ROOT = 0x2020202020202020202020202020202020202020202020202020202020202020;

    BeaconLightClient lightclient;
    MockBLS bls;
    address self;

    function setUp() public {
        bls = new MockBLS();
        lightclient = new BeaconLightClient(
            address(bls),
            0,
            0,
            bytes32(0),
            bytes32(0),
            bytes32(0),
            CURRENT_SYNC_COMMITTEE_ROOT,
            GENESIS_VALIDATORS_ROOT
        );
        self = address(this);
    }

    function test_constructor_args() public {

    }

    function test_import_next_sync_committee() public {
        BeaconBlockHeader memory finalized_header = build_finalized_header();
        process_import_finalized_header(finalized_header);
        bytes32[] memory next_sync_committee_branch = build_next_sync_committee_branch();
        BeaconLightClient.SyncCommitteePeriodUpdate memory update = BeaconLightClient.SyncCommitteePeriodUpdate({
            next_sync_committee: sync_committee_case1(),
            next_sync_committee_branch: next_sync_committee_branch
        });
        lightclient.import_next_sync_committee(update);
        bytes32 stored_next_sync_committee_root = lightclient.sync_committee_roots(1);
        assertEq(hash_tree_root(sync_committee_case1()), stored_next_sync_committee_root);
    }

    function test_import_finalized_header() public {
        BeaconBlockHeader memory finalized_header = build_finalized_header();
        process_import_finalized_header(finalized_header);
        assert_finalized_header(finalized_header);
    }

    function assert_finalized_header(BeaconBlockHeader memory finalized_header) public {
        (uint64 slot, uint64 proposer_index, bytes32 parent_root, bytes32 state_root, bytes32 body_root) = lightclient.finalized_header();
        bytes32 stored_latest_execution_payload_state_root = lightclient.state_root();
        assertEq(uint(slot), finalized_header.slot);
        assertEq(uint(proposer_index), finalized_header.proposer_index);
        assertEq(parent_root, finalized_header.parent_root);
        assertEq(state_root, finalized_header.state_root);
        assertEq(body_root, finalized_header.body_root);
        assertEq(stored_latest_execution_payload_state_root, LATEST_EXECUTION_PAYLOAD_STATE_ROOT);
    }

    function process_import_finalized_header(BeaconBlockHeader memory finalized_header) public {
        bytes32[] memory finality_branch = build_finality_branch();
        bytes32[] memory latest_execution_payload_state_root_branch = build_latest_execution_payload_state_root_branch();

        BeaconLightClient.FinalizedHeaderUpdate memory update = BeaconLightClient.FinalizedHeaderUpdate({
            attested_header: BeaconBlockHeader({
                slot: 160,
                proposer_index: 97,
                parent_root: 0xedcc9449fd2115936babbddb9e542d4e19174d57b4dc6b1d35beafe7ad36a74a,
                state_root: 0x8bfc033696d841842579ef3c57c9513d4e8ab433bb317bac2f7c31213c147ef9,
                body_root: 0x4d9a9d5e540ea67b9c6fe1aa133dd4e28690baaf5bb52c323058027683d07700
            }),
            signature_sync_committee: sync_committee_case1(),
            finalized_header: finalized_header,
            finality_branch: finality_branch,
            latest_execution_payload_state_root: LATEST_EXECUTION_PAYLOAD_STATE_ROOT,
            latest_execution_payload_state_root_branch: latest_execution_payload_state_root_branch,
            sync_aggregate: BeaconLightClient.SyncAggregate({
                sync_committee_bits:[
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                ],
                sync_committee_signature: hex'97f0ff2a00f9c8ffe0ff6b1bad3b97c6aa856c9ca3c49e10bb8aeab202ebffa6723a22ec28f9f94ab5f7719a14aa55301520b1ff6bb9f430d786e803096336697237036816d4be2355adfd7fb12d2c307ec6d25c051f3930d24c7ee1fd1ae1ee'
            }),
            fork_version: 0x02000000,
            signature_slot: 161
        });
        lightclient.import_finalized_header(update);
    }

    function build_finalized_header() internal pure returns (BeaconBlockHeader memory) {
        BeaconBlockHeader memory finalized_header = BeaconBlockHeader({
                slot: 96,
                proposer_index: 113,
                parent_root: 0x99f6f578c9ff1a59507933cd1de43a28ee02c32e894d03cf2a382e3ed2256977,
                state_root: 0xa825a60c126ea9a888c50f42a2cc29c08e77885d76181a710a11a7f29d7b5232,
                body_root: 0xf1de2a5c6f97ef03b9d5e0791e0f931a4b99c6e8b648aeeef5af3ed619817938
        });
        return finalized_header;
    }

    function build_finality_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x0300000000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0x504e8dfadf27180c21c80f1886b202de4c1c89ee2977562433abbbc92ea194e6;
        finality_branch[2] = 0x923ebc2107d5288dad0afd4187e0fe6caae2df92fcf6252ce7ce7feea56e7152;
        finality_branch[3] = 0x0d6c8237c3afc47b3f106446741506929a40f9df741c0770bee5f344b8aab742;
        finality_branch[4] = 0x871bcb4ed163da445bde2b51bae86a95a0fb1a303505df32f5fa420b6be0a5f1;
        finality_branch[5] = 0xd0c6412458c36a5c6d3d77cbbff88f3de7f430ca2da501fd206f7a1534044f50;
        return finality_branch;
    }

    function build_next_sync_committee_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory next_sync_committee_branch = new bytes32[](5);
        next_sync_committee_branch[0] = 0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7;
        next_sync_committee_branch[1] = 0xc15a3515c2f69c510d27dc829bb763a071d12ed28861665a15eac18be09ec396;
        next_sync_committee_branch[2] = 0x89f0fe943eccdd57a2157d7e2be84242bec60c625333625cc8d694bb7ec5585a;
        next_sync_committee_branch[3] = 0x464fc1fecf4397821c0e525c1879dfdce222f594bb30ab9ee9796e6a61661189;
        next_sync_committee_branch[4] = 0x888fcb085245c3f527c9970cb9e2baa448489971cc2d642c579e43c43b48a931;
        return next_sync_committee_branch;
    }

    function build_latest_execution_payload_state_root_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory latest_execution_payload_state_root_branch = new bytes32[](9);
        latest_execution_payload_state_root_branch[0] = 0x6e6f207265636569707473206865726500000000000000000000000000000000;
        latest_execution_payload_state_root_branch[1] = 0x0da04860fe44433e504e6cb82bd33d75e6777a42e61945b5b5fb1419c71154b0;
        latest_execution_payload_state_root_branch[2] = 0x652fbde7e8c386fa3bb4eb78d00554151bde57883b291ab2518daec002b8b3b0;
        latest_execution_payload_state_root_branch[3] = 0x812d7693874fe376731eed84416c67a6ed1a2a6799c562016882c88b866afc98;
        latest_execution_payload_state_root_branch[4] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        latest_execution_payload_state_root_branch[5] = 0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b;
        latest_execution_payload_state_root_branch[6] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        latest_execution_payload_state_root_branch[7] = 0x2e04867cf7c3b3e8e9e7b200d79e4a508ad69a3fe24fae94455458f5b151c573;
        latest_execution_payload_state_root_branch[8] = 0x888fcb085245c3f527c9970cb9e2baa448489971cc2d642c579e43c43b48a931;
        return latest_execution_payload_state_root_branch;
    }
}
