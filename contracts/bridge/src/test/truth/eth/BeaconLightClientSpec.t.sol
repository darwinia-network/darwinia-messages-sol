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

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../test.sol";
import "../../mock/MockBLS.sol";
import "../../spec/SyncCommittee.t.sol";
import "../../../truth/eth/BeaconLightClient.sol";
import "../../../truth/eth/ExecutionLayer.sol";

contract BeaconLightClientSpecTest is DSTest, SyncCommitteePreset {

    bytes32 constant CURRENT_SYNC_COMMITTEE_ROOT = 0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7;
    bytes32 constant GENESIS_VALIDATORS_ROOT = 0x32251a5a748672e3acb1e574ec27caf3b6be68d581c44c402eb166d71a89808e;
    bytes32 constant LATEST_EXECUTION_PAYLOAD_STATE_ROOT = 0x2020202020202020202020202020202020202020202020202020202020202020;

    BeaconLightClient lightclient;
    ExecutionLayer executionlayer;
    MockBLS bls;
    address self;

    function setUp() public {
        bls = new MockBLS();
        lightclient = new BeaconLightClient(
            address(bls),
            64,
            178,
            0x845ff39213447cef03dfc6dd1a01e224a82c37213361877d66a8931289c61af0,
            0x65d4f36e0296cbdb26975ca018bdedf8e795a6199081e78ab284aeaceaab5e1e,
            0x59104a2242970ad68e652528e849a8affbf73923aa674452422151b135da707a,
            CURRENT_SYNC_COMMITTEE_ROOT,
            GENESIS_VALIDATORS_ROOT
        );
        executionlayer = new ExecutionLayer(address(lightclient));
        self = address(this);
    }

    function test_constructor_args() public {}

    function test_sync_committee_period_update() public {
        BeaconLightClient.FinalizedHeaderUpdate memory header_update = build_header_update();
        bytes32[] memory next_sync_committee_branch = build_next_sync_committee_branch();
        BeaconLightClient.SyncCommitteePeriodUpdate memory sc_update = BeaconLightClient.SyncCommitteePeriodUpdate({
            next_sync_committee: sync_committee_case1(),
            next_sync_committee_branch: next_sync_committee_branch
        });
        lightclient.sync_committee_period_update(header_update, sc_update);
        bytes32 stored_next_sync_committee_root = lightclient.sync_committee_roots(1);
        assertEq(hash_tree_root(sync_committee_case1()), stored_next_sync_committee_root);
        assert_finalized_header();
    }

    // function test_import_latest_execution_payload_state_root() public {
    //     BeaconBlockHeader memory finalized_header = build_finalized_header();
    //     process_import_finalized_header(finalized_header);
    //     bytes32[] memory latest_execution_payload_state_root_branch = build_latest_execution_payload_state_root_branch();
    //     ExecutionLayer.ExecutionPayloadStateRootUpdate memory update = ExecutionLayer.ExecutionPayloadStateRootUpdate({
    //         latest_execution_payload_state_root: LATEST_EXECUTION_PAYLOAD_STATE_ROOT,
    //         latest_execution_payload_state_root_branch: latest_execution_payload_state_root_branch
    //     });
    //     executionlayer.import_latest_execution_payload_state_root(update);
    //     assertEq(executionlayer.merkle_root(), LATEST_EXECUTION_PAYLOAD_STATE_ROOT);
    // }

    function test_import_finalized_header() public {
        process_import_finalized_header();
        assert_finalized_header();
    }

    function assert_finalized_header() public {
        BeaconBlockHeader memory finalized_header = build_finalized_header();
        (uint64 slot, uint64 proposer_index, bytes32 parent_root, bytes32 state_root, bytes32 body_root) = lightclient.finalized_header();
        assertEq(uint(slot), finalized_header.slot);
        assertEq(uint(proposer_index), finalized_header.proposer_index);
        assertEq(parent_root, finalized_header.parent_root);
        assertEq(state_root, finalized_header.state_root);
        assertEq(body_root, finalized_header.body_root);
    }

    function process_import_finalized_header() public {
        BeaconLightClient.FinalizedHeaderUpdate memory update = build_header_update();
        lightclient.import_finalized_header(update);
    }

    function build_header_update() internal pure returns (BeaconLightClient.FinalizedHeaderUpdate memory update) {

        return BeaconLightClient.FinalizedHeaderUpdate({
            attested_header: BeaconBlockHeader({
                slot: 160,
                proposer_index: 80,
                parent_root: 0x137897af1cfe1fb5653ef013071bd1aeef1ef3f0c3bd512231f55c64e719e425,
                state_root: 0x6c97e36f19a53e29b6cb929c40cda7da84468da3c25e11dec111b053b8f14f7b,
                body_root: 0x86197db1dfc43279b94bb219c5b0b150b722ea241f5c406febc10a6981bd0253
            }),
            signature_sync_committee: sync_committee_case0(),
            finalized_header: build_finalized_header(),
            finality_branch: build_finality_branch(),
            sync_aggregate: BeaconLightClient.SyncAggregate({
                sync_committee_bits:[
                    bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
                    bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                ],
                sync_committee_signature: hex'b358a925402e6fe4d06ae46ee53dd9eae9e2196db80bc2260defc44375a2deeb68e7270c659994ea2a67268d9083822f0befcb3e0676ad928fff2a776de0e768384b716b0bba0e539376b53ad7a50062db8d15cae62f5cdea38b5a2f7c78810d'
            }),
            fork_version: 0x02000000,
            signature_slot: 161
        });
    }

    function build_finalized_header() internal pure returns (BeaconBlockHeader memory) {
        BeaconBlockHeader memory finalized_header = BeaconBlockHeader({
                slot: 96,
                proposer_index: 113,
                parent_root: 0xbdabcb2cd4fa844539e5b6980bf041ec82ba9fe6c4fa96c891aae138a21a93fd,
                state_root: 0x39ccd3ef13c880134355d74ebaa99a7278635ed60783affe0133a246cc56dc35,
                body_root: 0x5d89f947b76eac1403fe2bd69c8105bba903e3165a446a666801946f33b561fe
        });
        return finalized_header;
    }

    function build_finality_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x0300000000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0x504e8dfadf27180c21c80f1886b202de4c1c89ee2977562433abbbc92ea194e6;
        finality_branch[2] = 0x923ebc2107d5288dad0afd4187e0fe6caae2df92fcf6252ce7ce7feea56e7152;
        finality_branch[3] = 0x3b577201ee2acf74f666554f686190815f946fb75d2ed0298049c1c355a47396;
        finality_branch[4] = 0x09875983a2cd4d0bccde54922b07c0a4e4832139eec3ff74923ee7bb62c6bfa5;
        finality_branch[5] = 0x734497db34118c6e840c5ed0c285cc1dfa9cbe350ad4cdf47f1fa8beef46a84e;
        return finality_branch;
    }

    function build_next_sync_committee_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory next_sync_committee_branch = new bytes32[](5);
        next_sync_committee_branch[0] = 0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7;
        next_sync_committee_branch[1] = 0x739dc8b520bf91a2540c45abda7a4f3ac7538ddffbd850dfdeb70645da18fc6f;
        next_sync_committee_branch[2] = 0x3b577201ee2acf74f666554f686190815f946fb75d2ed0298049c1c355a47396;
        next_sync_committee_branch[3] = 0x09875983a2cd4d0bccde54922b07c0a4e4832139eec3ff74923ee7bb62c6bfa5;
        next_sync_committee_branch[4] = 0x734497db34118c6e840c5ed0c285cc1dfa9cbe350ad4cdf47f1fa8beef46a84e;
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
