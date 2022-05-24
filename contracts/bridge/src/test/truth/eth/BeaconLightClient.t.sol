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
        bytes32 genesis_validators_root = 0x2167a9b325b2a1c53d429e2e843f45551c37dd8d1394023f9a620a7b3d3fec4b;
        lightclient.process_light_client_update(update, genesis_validators_root);
    }

    function test_process_light_client_update_finality_updated() public {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x0300000000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0x504e8dfadf27180c21c80f1886b202de4c1c89ee2977562433abbbc92ea194e6;
        finality_branch[2] = 0x923ebc2107d5288dad0afd4187e0fe6caae2df92fcf6252ce7ce7feea56e7152;
        finality_branch[3] = 0x8e72730db07789249338535f2668e3346e3b6ce9e362edfd94963ea179076cad;
        finality_branch[4] = 0x67a03e91b6a7fc88bf6e89bfa72b55574fa0ac08b67f4b696d0adc3b5d2c7601;
        finality_branch[5] = 0x41666f06535af01c6021cd882996774b6c2b942c0996737de614e41963b25ba5;
        BeaconLightClient.LightClientUpdate memory update = BeaconLightClient.LightClientUpdate({
            attested_header: BeaconBlockHeader({
                slot: 160,
                proposer_index: 28,
                parent_root: 0xe96b675c7bd3f38386a7639fd5cb962b5ba9f5287007242779a4fc31638debe6,
                state_root: 0xe172c5cce320bb6fbddb973f27d1ff55d1f68a57cc7ed6d53d7faffb4037d960,
                body_root: 0x7d4d425497a1ff7d3658d3abf1cb0a9fa1ccc0dd5a7dbacd2be00ce49184bc78
            }),
            current_sync_committee: sync_committee_case1(),
            next_sync_committee: sync_committee_case1(),
            next_sync_committee_branch: new bytes32[](5),
            finalized_header: BeaconBlockHeader({
                slot: 96,
                proposer_index: 113,
                parent_root: 0x5995141e1d2ccaf168aec075e065581e1f9ecb469a377546da2e356f7eb14f9d,
                state_root: 0x3080e7d19b5604a53bb143d26a7d71c848bd25f2e9258ad346bff5571d91daa9,
                body_root: 0xdedb62ddc1b19106f716916fb698562652a6822108cc9c81c6eb2bd7f2b07433
            }),
            finality_branch: finality_branch,
            sync_aggregate: BeaconLightClient.SyncAggregate({
                sync_committee_bits:[
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                ],
                sync_committee_signature: hex'a45ded60fac188920c0691ded62fdde57755c9da591061fc15acf8b4b4af1eebefdcf741aab41ba99281d284917a61231251db63f479246d8e7cdaec3d316bf9c603a5d8c53b75f17ec4c30fb64e4eced018b532e635b3f214c666e425832052'
            }),
            fork_version: 0x00000000
        });
        bytes32 genesis_validators_root = 0x2167a9b325b2a1c53d429e2e843f45551c37dd8d1394023f9a620a7b3d3fec4b;
        lightclient.process_light_client_update(update, genesis_validators_root);
    }
}
