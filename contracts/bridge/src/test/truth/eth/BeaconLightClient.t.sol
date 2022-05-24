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
            0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7
        );
        self = address(this);
    }

    function test_constructor_args() public {

    }

    function test_process_light_client_update() public {
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
            sync_aggregate: BeaconLightClient.SyncAggregate({
                sync_committee_bits:[
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                ],
                sync_committee_signature: hex'8b01fd3337e1f7485430444c91bffc5b31d3e2b18a1fbd4478fd7ca56c974d1ee4d4f88a271fea7344a9956f1a77bb0e0c3d0006b7e1bad5c0afabf525787d280919a3c6a4d53c159cb87c8a76e702a26d1471575f5b02feee7824b484b23430'
            }),
            fork_version: 0x00000000
        });
    }
}
