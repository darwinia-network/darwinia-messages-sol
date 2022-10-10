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

    // capella version in lodestar
    function testFail_update_sync_committee_period() public {
        BeaconLightClient.FinalizedHeaderUpdate memory header_update = build_header_update();
        bytes32[] memory next_sync_committee_branch = build_next_sync_committee_branch();
        BeaconLightClient.SyncCommitteePeriodUpdate memory sc_update = BeaconLightClient.SyncCommitteePeriodUpdate({
            next_sync_committee: sync_committee_case1(),
            next_sync_committee_branch: next_sync_committee_branch
        });
        lightclient.update_sync_committee_period(header_update, sc_update);
        bytes32 stored_next_sync_committee_root = lightclient.sync_committee_roots(1);
        assertEq(hash_tree_root(sync_committee_case1()), stored_next_sync_committee_root);
        assert_finalized_header();
    }

    function test_import_latest_execution_payload_state_root() public {
        process_import_finalized_header();
        BeaconBlockBody memory body = build_beacon_block_body();
        executionlayer.import_latest_execution_payload_state_root(body);
        assertEq(executionlayer.merkle_root(), LATEST_EXECUTION_PAYLOAD_STATE_ROOT);
    }

    function test_import_finalized_header() public {
        process_import_finalized_header();
        assert_finalized_header();
    }

    function test_hash_body() public {
        BeaconBlockBody memory body = build_beacon_block_body();
        assertEq(hash_tree_root(body), 0x5d89f947b76eac1403fe2bd69c8105bba903e3165a446a666801946f33b561fe);
    }

    function test_hash_execution_payload() public {
        ExecutionPayload memory payload = build_execution_payload();
        assertEq(hash_tree_root(payload), 0x2490713379e5aa8bee358bbfe709fe283e3a291a3566f04bad8d9a185d08d738);
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

    function build_header_update() internal pure returns (BeaconLightClient.FinalizedHeaderUpdate memory) {
        return BeaconLightClient.FinalizedHeaderUpdate({
            attested_header: BeaconBlockHeader({
                slot:           160,
                proposer_index: 80,
                parent_root:    0x137897af1cfe1fb5653ef013071bd1aeef1ef3f0c3bd512231f55c64e719e425,
                state_root:     0x6c97e36f19a53e29b6cb929c40cda7da84468da3c25e11dec111b053b8f14f7b,
                body_root:      0x86197db1dfc43279b94bb219c5b0b150b722ea241f5c406febc10a6981bd0253
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
                slot:           96,
                proposer_index: 113,
                parent_root:    0xbdabcb2cd4fa844539e5b6980bf041ec82ba9fe6c4fa96c891aae138a21a93fd,
                state_root:     0x39ccd3ef13c880134355d74ebaa99a7278635ed60783affe0133a246cc56dc35,
                body_root:      0x5d89f947b76eac1403fe2bd69c8105bba903e3165a446a666801946f33b561fe
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

    function build_execution_payload() internal pure returns (ExecutionPayload memory) {
        return ExecutionPayload({
                 parent_hash:      0x086a5176b7264ec055146c18cf00fbfbc17e1d5b8e329d05ee31e646ccb8bc25,
                 fee_recipient:    0x0000000000000000000000000000000000000000,
                 state_root:       0x2020202020202020202020202020202020202020202020202020202020202020,
                 receipts_root:    0x6e6f207265636569707473206865726500000000000000000000000000000000,
                 logs_bloom:       0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c,
                 prev_randao:      0x8bfd65d9fced9ebead59f7b12c45476bae9e8d076b91b29f8825b497b39a79d5,
                 block_number:     2,
                 gas_limit:        30000000,
                 gas_used:         0,
                 timestamp:        1152,
                 extra_data:       0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b,
                 base_fee_per_gas: 1000000000,
                 block_hash:       0x99af7944c07bc4f6cd2901a63652d4e4286671734e753370d1401f6bd4e7e1f4,
                 transactions:     0x7ffe241ea60187fdb0187bfa22de35d1f9bed7ab061d9401fd47e34a54fbede1
             });
    }

    function build_beacon_block_body() internal pure returns (BeaconBlockBody memory) {
        return BeaconBlockBody({
             randao_reveal:      0xfa342089de677fac3ed4de0a50c4518ab6a9bb1f7487276f68a703c1b4874e86,
             eth1_data:          0xe5a8983c1b75fb1729d091f72018e4b50dd9d12afe19c4fed929dd16403cb0b8,
             graffiti:           0x0000000000000000000000000000000000000000000000000000000000000000,
             proposer_slashings: 0x792930bbd5baac43bcc798ee49aa8185ef76bb3b44ba62b91d86ae569e4bb535,
             attester_slashings: 0x7a0501f5957bdf9cb3a8ff4966f02265f968658b7a9c62642cba1165e86642f5,
             attestations:       0x0ce8502857380438a71857e962e99296ecf70c4f8996d381a10030ff14a3329b,
             deposits:           0x792930bbd5baac43bcc798ee49aa8185ef76bb3b44ba62b91d86ae569e4bb535,
             voluntary_exits:    0x792930bbd5baac43bcc798ee49aa8185ef76bb3b44ba62b91d86ae569e4bb535,
             sync_aggregate:     0x50dbcb1fd7c53f50bb3bd1a30640f38eec60300722977902a47779cae66d448c,
             execution_payload:  build_execution_payload()
        });
    }

}
