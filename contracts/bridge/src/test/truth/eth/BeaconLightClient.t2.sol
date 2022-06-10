// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../test.sol";
import "../../mock/MockBLS.sol";
import "../../../utils/Bitfield.sol";
import "../../spec/SyncCommittee.t.sol";
import "../../../truth/eth/BeaconLightClient.sol";

contract BeaconLightClientTest2 is DSTest, Bitfield, SyncCommitteePreset {
    bytes32 constant CURRENT_SYNC_COMMITTEE_ROOT = 0x9c27f72afdc11a64a3f0c7246fe5ed2aa6303a1cb06bb0a7be746528ee97741d;
    bytes32 constant GENESIS_VALIDATORS_ROOT = 0x99b09fcd43e5905236c370f184056bec6e6638cfc31a323b304fc4aa789cb4ad;
    bytes32 constant LATEST_EXECUTION_PAYLOAD_STATE_ROOT = 0x0af4e189e2b2e9e22e1f5ba516e14b4bbc2a617af7991e1b095dd0ffe1763353;
    BeaconLightClient lightclient;
    MockBLS bls;
    address self;

    function setUp() public {
        bls = new MockBLS();
        lightclient = new BeaconLightClient(
            address(bls),
            594880,
            62817,
            0x961949592705567a50aae3f4186852f44dfeeb9688df46f7f49ef4a626f60b9a,
            0x768a9a1694fd36f6d9523be1e49b690dc4ab2934ba46fa99ad110f03b4a785c4,
            0x2983d20d70763f6d1e619f98f83e9ba7a8a84e7b10d82085e4e192c6ff2b9b76,
            CURRENT_SYNC_COMMITTEE_ROOT,
            GENESIS_VALIDATORS_ROOT
        );
        self = address(this);
    }

    function test_constructor_args() public {

    }

    // function testFail_import_next_sync_committee() public {
    //     BeaconBlockHeader memory finalized_header = build_finalized_header();
    //     process_import_finalized_header(finalized_header);
    //     bytes32[] memory next_sync_committee_branch = build_next_sync_committee_branch();
    //     BeaconLightClient.SyncCommitteePeriodUpdate memory update = BeaconLightClient.SyncCommitteePeriodUpdate({
    //         next_sync_committee: sync_committee_case1(),
    //         next_sync_committee_branch: next_sync_committee_branch
    //     });
    //     lightclient.import_next_sync_committee(update);
    //     bytes32 stored_next_sync_committee_root = lightclient.sync_committee_roots(1);
    //     assertEq(hash_tree_root(sync_committee_case1()), stored_next_sync_committee_root);
    // }

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
                slot: 594977,
                proposer_index: 75461,
                parent_root: 0x728e25e46c1a25871bf7fd2f166f9df498258a9a53b00da023bebe1af95802ca,
                state_root: 0xfc0692a950c8eb6f0c1e979151ce07a4f01c13187bbf937406bfa2e71e3e4eb1,
                body_root: 0x297f7ba3dad4b07d238ffab5af582c24c3441598f4901600926db5ed8a6a41ca
            }),
            current_sync_committee: sync_committee_case3(),
            finalized_header: finalized_header,
            finality_branch: finality_branch,
            latest_execution_payload_state_root: LATEST_EXECUTION_PAYLOAD_STATE_ROOT,
            latest_execution_payload_state_root_branch: latest_execution_payload_state_root_branch,
            sync_aggregate: BeaconLightClient.SyncAggregate({
                sync_committee_bits:[
                    0xfbbdffdeffff7efdcefebfffff37f7fffbddbbf7fffff7dfe77bbfffffcffbfd,
                    0xeffffdff79fffffbffffbf9ffffff7fe7fffdd6feffb7fbfff7fbffb7ffbdffd
                ],
                sync_committee_signature: hex'afef0939a9e716283e11070e716a96cbeab8af6e4d695bf3366ea9d4dcb5aaa24841da1f7c9534d6aafe2bf1d79ea2b10a7a2748d9c3b602eb5f364c7fac1a2b9fa986d4bb075d3d6a68ad1186a2a46f2359ee8c27ad7726703969255c6dcfdd'
            }),
            fork_version: 0x70000071
        });
        lightclient.import_finalized_header(update);
    }

    function build_finalized_header() internal pure returns (BeaconBlockHeader memory) {
        BeaconBlockHeader memory finalized_header = BeaconBlockHeader({
                slot: 594911,
                proposer_index: 43690,
                parent_root: 0x3974cf326930ccf93f2be5a8d31106adc82028928b2e67acb5e9b0ee48eda502,
                state_root: 0xcdfc3f85ae19b0e98abfc28a16fb88b11ac63ab893ec25941316c918aa3a1f73,
                body_root: 0xdf9163209fd849261083d009c5fe9f9a6ee1627b9e09947c21e5ffa63356c642
        });
        return finalized_header;
    }

    function build_finality_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x9f48000000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0x93ebd672751f2a3f9191d3f770942d9e572751a266da914b84f25924ec44f582;
        finality_branch[2] = 0x22c6ee46a3ecb5224660a5775f7e652ad3f823de4dbbbf7bb1d87b93a3dcbed4;
        finality_branch[3] = 0xc2a324aa1ee13deea1c3cbaaf93515c754b9b74c4ddc933fa25d8cadaf5d1e5a;
        finality_branch[4] = 0xa7abfadf3ccbf0025cf763dc900693a6eff8ea40770c74751375e92aea8fcc5c;
        finality_branch[5] = 0x28d2b66282f076776263727d18591ea8132bbf59e1542a0c1c414f03a8a66d8f;
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
        latest_execution_payload_state_root_branch[0] = 0x9fafc4a23cbaa040c49376f62a2b10eba9ebbb35549cec4e57df5c67a5dcc2f7;
        latest_execution_payload_state_root_branch[1] = 0x6a468d1d3d143265db8dfd97fe883b5cac1981f9c65049989ab6231090271024;
        latest_execution_payload_state_root_branch[2] = 0xf649714b466da8b6582d6c7ae1f4fade53b7785720f05c6782acea38faa57735;
        latest_execution_payload_state_root_branch[3] = 0x0720e5566d1539210bd4e9bfe1fdf93c9b74a43f73211eb59e26425abfffa282;
        latest_execution_payload_state_root_branch[4] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        latest_execution_payload_state_root_branch[5] = 0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b;
        latest_execution_payload_state_root_branch[6] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        latest_execution_payload_state_root_branch[7] = 0x696d3bbc9e8d29299e6f04b53c86a09089664d1b068e4a8c5b44c190e2e809d1;
        latest_execution_payload_state_root_branch[8] = 0x7993149c1f6389cd03076c2e98e762ac90e66d2bed9556a8f49e0a391ae52303;
        return latest_execution_payload_state_root_branch;
    }

    function sum(uint256[2] memory x) internal pure returns (uint256) {
        return countSetBits(x[0]) + countSetBits(x[1]);
    }

    function test_sum_sync_committee_bits() public {
        uint[2] memory sync_committee_bits = [
            0xfbbdffdeffff7efdcefebfffff37f7fffbddbbf7fffff7dfe77bbfffffcffbfd,
            0xeffffdff79fffffbffffbf9ffffff7fe7fffdd6feffb7fbfff7fbffb7ffbdffd
        ];
        assertEq(sum(sync_committee_bits), 451);
    }
}
