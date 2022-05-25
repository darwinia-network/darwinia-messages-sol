// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../test.sol";
import "../../../truth/eth/BeaconLightClient.sol";
import "../../spec/SyncCommittee.t.sol";

contract BeaconLightClientTest is DSTest, SyncCommitteePreset {
    BeaconLightClient lightclient;
    address public self;

    function setUp() public {
        lightclient = new BeaconLightClient(
            0,
            0,
            bytes32(0),
            bytes32(0),
            bytes32(0),
            0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7,
            0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7
        );
        self = address(this);
    }

    function test_constructor_args() public {

    }

    function testFail_process_light_client_update() public {
        BeaconLightClient.LightClientUpdate memory update = BeaconLightClient.LightClientUpdate({
            attested_header: BeaconBlockHeader({
                slot: 1,
                proposer_index: 174,
                parent_root: 0x7e19842e44e9a4546222cd9ede102507ec36ce4d33185e173eca9f75e02b5636,
                state_root: 0x1c4ce4b12145a9b8b33ee1472f9ea4d34fc2101b19f33328e78db59ff55c6c26,
                body_root: 0xc98f7eb7b0717147f0161707bd3ad536417511b982e273652d0d879280e76972
            }),
            current_sync_committee: sync_committee_case1(),
            next_sync_committee: sync_committee_case1(),
            next_sync_committee_branch: new bytes32[](5),
            finalized_header: BeaconBlockHeader({
                slot: 0,
                proposer_index: 0,
                parent_root: 0x0000000000000000000000000000000000000000000000000000000000000000,
                state_root: 0x0000000000000000000000000000000000000000000000000000000000000000,
                body_root: 0x0000000000000000000000000000000000000000000000000000000000000000
            }),
            finality_branch: new bytes32[](6),
            latest_execution_payload_state_root: bytes32(0),
            latest_execution_payload_state_root_branch: new bytes32[](9),
            sync_aggregate: BeaconLightClient.SyncAggregate({
                sync_committee_bits:[
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                ],
                sync_committee_signature: hex'8b01fd3337e1f7485430444c91bffc5b31d3e2b18a1fbd4478fd7ca56c974d1ee4d4f88a271fea7344a9956f1a77bb0e0c3d0006b7e1bad5c0afabf525787d280919a3c6a4d53c159cb87c8a76e702a26d1471575f5b02feee7824b484b23430'
            }),
            fork_version: 0x00000000
        });
        bytes32 genesis_validators_root = 0x2167a9b325b2a1c53d429e2e843f45551c37dd8d1394023f9a620a7b3d3fec4b;
        lightclient.process_light_client_update(update, genesis_validators_root);
    }

    function test_process_light_client_update_finality_updated() public {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x0300000000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0x504e8dfadf27180c21c80f1886b202de4c1c89ee2977562433abbbc92ea194e6;
        finality_branch[2] = 0x923ebc2107d5288dad0afd4187e0fe6caae2df92fcf6252ce7ce7feea56e7152;
        finality_branch[3] = 0x0d6c8237c3afc47b3f106446741506929a40f9df741c0770bee5f344b8aab742;
        finality_branch[4] = 0x871bcb4ed163da445bde2b51bae86a95a0fb1a303505df32f5fa420b6be0a5f1;
        finality_branch[5] = 0xd0c6412458c36a5c6d3d77cbbff88f3de7f430ca2da501fd206f7a1534044f50;

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

        BeaconLightClient.LightClientUpdate memory update = BeaconLightClient.LightClientUpdate({
            attested_header: BeaconBlockHeader({
                slot: 160,
                proposer_index: 97,
                parent_root: 0xedcc9449fd2115936babbddb9e542d4e19174d57b4dc6b1d35beafe7ad36a74a,
                state_root: 0x8bfc033696d841842579ef3c57c9513d4e8ab433bb317bac2f7c31213c147ef9,
                body_root: 0x4d9a9d5e540ea67b9c6fe1aa133dd4e28690baaf5bb52c323058027683d07700
            }),
            current_sync_committee: sync_committee_case1(),
            next_sync_committee: sync_committee_case1(),
            next_sync_committee_branch: new bytes32[](5),
            finalized_header: BeaconBlockHeader({
                slot: 96,
                proposer_index: 113,
                parent_root: 0x99f6f578c9ff1a59507933cd1de43a28ee02c32e894d03cf2a382e3ed2256977,
                state_root: 0xa825a60c126ea9a888c50f42a2cc29c08e77885d76181a710a11a7f29d7b5232,
                body_root: 0xf1de2a5c6f97ef03b9d5e0791e0f931a4b99c6e8b648aeeef5af3ed619817938
            }),
            finality_branch: finality_branch,
            latest_execution_payload_state_root: 0x2020202020202020202020202020202020202020202020202020202020202020,
            latest_execution_payload_state_root_branch: latest_execution_payload_state_root_branch,
            sync_aggregate: BeaconLightClient.SyncAggregate({
                sync_committee_bits:[
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                ],
                sync_committee_signature: hex'97f0ff2a00f9c8ffe0ff6b1bad3b97c6aa856c9ca3c49e10bb8aeab202ebffa6723a22ec28f9f94ab5f7719a14aa55301520b1ff6bb9f430d786e803096336697237036816d4be2355adfd7fb12d2c307ec6d25c051f3930d24c7ee1fd1ae1ee'
            }),
            fork_version: 0x02000000
        });
        bytes32 genesis_validators_root = 0x32251a5a748672e3acb1e574ec27caf3b6be68d581c44c402eb166d71a89808e;
        lightclient.process_light_client_update(update, genesis_validators_root);
    }
}
