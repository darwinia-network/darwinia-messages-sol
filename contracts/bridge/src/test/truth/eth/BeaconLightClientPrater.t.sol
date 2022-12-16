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

import "../../test.sol";
import "../../mock/MockBLS.sol";
import "../../../utils/Bitfield.sol";
import "../../spec/SyncCommittee.t.sol";
import "../../../spec/BeaconLightClientUpdate.sol";
import "../../../truth/eth/BeaconLightClient.sol";
import "../../../truth/eth/ExecutionLayer.sol";


contract BeaconLightClientPraterTest is DSTest, BeaconLightClientUpdate, Bitfield, SyncCommitteePreset {
    bytes32 constant CURRENT_SYNC_COMMITTEE_ROOT = 0xa36ba14c9ad227f9785a6b9ffd52d3b1f40a3fbd73e7445e18f70cac121612b4;
    bytes32 constant GENESIS_VALIDATORS_ROOT = 0x043db0d9a83813551ee2f33450d23797757d430911a9320530ad8a0eabc43efb;
    bytes32 constant LATEST_EXECUTION_PAYLOAD_STATE_ROOT = 0xba2cb8f2d80e266a1e69845b10224430f4667f3da4273174c9b243a8661e91fe;

    BeaconLightClient lightclient;
    ExecutionLayer executionlayer;
    MockBLS bls;
    address self;

    function setUp() public {
        bls = new MockBLS();
        lightclient = new BeaconLightClient(
            address(bls),
            4063328,
            353355,
            0x964a8c23cedbb4f2a44749e317ed2612b02eee158bea49e629fcbf8852f523d1,
            0xc98b933323521f9cbf5318e8ca0d3737db76811a9232b35de9587763bd8ea05a,
            0xe59b964884eb33a1cce0b2507da841651ac61be559c7020f57d61fb212ce3e57,
            CURRENT_SYNC_COMMITTEE_ROOT,
            GENESIS_VALIDATORS_ROOT
        );
        executionlayer = new ExecutionLayer(address(lightclient));
        self = address(this);
    }

    function test_constructor_args() public {}

    function test_import_next_sync_committee() public {
        FinalizedHeaderUpdate memory header_update = build_header_update();
        bytes32[] memory next_sync_committee_branch = build_next_sync_committee_branch();
        SyncCommitteePeriodUpdate memory sc_update = SyncCommitteePeriodUpdate({
            next_sync_committee: sync_committee_case3(),
            next_sync_committee_branch: next_sync_committee_branch
        });
        lightclient.import_next_sync_committee(header_update, sc_update);
        bytes32 stored_next_sync_committee_root = lightclient.sync_committee_roots(497);
        assertEq(hash_tree_root(sync_committee_case3()), stored_next_sync_committee_root);
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
        BeaconBlockHeader memory finalized_header = build_finalized_header1();
        (uint64 slot, uint64 proposer_index, bytes32 parent_root, bytes32 state_root, bytes32 body_root) = lightclient.finalized_header();
        assertEq(uint(slot), finalized_header.slot);
        assertEq(uint(proposer_index), finalized_header.proposer_index);
        assertEq(parent_root, finalized_header.parent_root);
        assertEq(state_root, finalized_header.state_root);
        assertEq(body_root, finalized_header.body_root);
    }

    function test_hash_body() public {
        BeaconBlockBody memory body = build_beacon_block_body();
        assertEq(hash_tree_root(body), 0xe683ebcb97b578a72f9c30533a8fdf046a9473408fd3bde3c68f56308eddb922);
    }

    function test_hash_execution_payload() public {
        ExecutionPayload memory payload = build_execution_payload();
        assertEq(hash_tree_root(payload), 0xd14091c659bef13f4f0c95aef5f1aebc46fc22caf4a87cb6a7174a32577d4b0c);
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
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x62f0010000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0x841c29464b336fb030eb99ed756f87c4ab777422ba9e172ce014bb9b8e7ec5b6;
        finality_branch[2] = 0xf5d713060e8a77425c6e350a7cda34e5b488c606deb3c873fd490dfc83c76ac5;
        finality_branch[3] = 0x7d6eef9d12048dcb660df3914cc0dc44decbd7693d40856f9004a87937e00798;
        finality_branch[4] = 0x91c80b14baaebb58d591fd3a5edad7b7f0972bc5ba1055c9d11f5ebb888cb0ee;
        finality_branch[5] = 0x4e328a0c4b7276c0307542e2e6785ba7a8043226e9ee05328c26eeca41e52590;

        FinalizedHeaderUpdate memory update = FinalizedHeaderUpdate({
            attested_header: BeaconBlockHeader({
                slot:           4066456,
                proposer_index: 169206,
                parent_root:    0x7123b887d02b692697999f03a445d815a8e4b950bce4db51fe5c25dbc164f685,
                state_root:     0xa88cab25b5d93ddfb41c4173ef976cc9a1f44071fa42c27954ba64ffa81f2aaf,
                body_root:      0x8a1a19e175acae182f3f7531b14402cb45d8c12038d8940e9eb9ad6b98f27f04
            }),
            signature_sync_committee: sync_committee_case2(),
            finalized_header: build_finalized_header1(),
            finality_branch: finality_branch,
            sync_aggregate: SyncAggregate({
                sync_committee_bits:[
                    bytes32(0x7ffeefbfffbf7bffbfe726feff6ffdfeef37f9dfa7b41fdd3fbfeffdffbe63f6),
                    bytes32(0xedffbfdf7fffdffbeb9ddfdfcfbefff97ff4e8ffef7d3ff759deff27fbbab7ff)
                ],
                sync_committee_signature: hex'8d51de130ba2af6dc637d7054807f62399ca085659b8f9d2c3a05f7400f4e43b213733f1b683f3b5000bf7c808e27f7c0771b2da1beefd004654f66a7c98ca3e462c2d980893d9cbed15f6e41396803565d0ad7013270b47c67535f48505bba3'
            }),
            fork_version: 0x02001020,
            signature_slot: 4066457
        });
        lightclient.import_finalized_header(update);
    }

    function build_header_update() internal pure returns (FinalizedHeaderUpdate memory) {
        return FinalizedHeaderUpdate({
            attested_header: BeaconBlockHeader({
                slot:           4063408,
                proposer_index: 178217,
                parent_root:    0x35adec31291c4e4e66d259f82e9c4a1063eff0c3f4fbfbdca70629c6e039fc53,
                state_root:     0x3b63548ca2fcbb6175651811185fe3c06b1f2529cb758e9049b69e02717dedc9,
                body_root:      0x8b1a74cef69937da01bb80c89a5263964ba5cee844f4abd49142446e84290bfb
            }),
            signature_sync_committee: sync_committee_case2(),
            finalized_header: build_finalized_header(),
            finality_branch: build_finality_branch(),
            sync_aggregate: SyncAggregate({
                sync_committee_bits:[
                    bytes32(0x7ffeefbfffbf7bffbff72efeff6ffdfeef37f9dfa7b41fdd3fbfeffdfffe67f6),
                    bytes32(0xfdffbfdf7ffffffbebbfdfdfcfbefffb7ff4e8ffef7dbff759deff27fbbab7ff)
                ],
                sync_committee_signature: hex'b4c2bade45ff0c4699c325fef661a8bc19b2704cb10f83c18b034702a6c9a6307abf36a1fa96850fae2947e6fcaeea5c11bbed1a29c6b7c1a4a30c6abe1d9ba9a0910ac45806306219b70b0650494dc04677551505af59c779db06860c30a3b1'
            }),
            fork_version: 0x02001020,
            signature_slot: 4063410
        });
    }

    function build_finalized_header() internal pure returns (BeaconBlockHeader memory) {
        BeaconBlockHeader memory finalized_header = BeaconBlockHeader({
                slot:           4063328,
                proposer_index: 353355,
                parent_root:    0x964a8c23cedbb4f2a44749e317ed2612b02eee158bea49e629fcbf8852f523d1,
                state_root:     0xc98b933323521f9cbf5318e8ca0d3737db76811a9232b35de9587763bd8ea05a,
                body_root:      0xe59b964884eb33a1cce0b2507da841651ac61be559c7020f57d61fb212ce3e57
        });
        return finalized_header;
    }

    function build_finalized_header1() internal pure returns (BeaconBlockHeader memory) {
        BeaconBlockHeader memory finalized_header = BeaconBlockHeader({
                slot:           4066368,
                proposer_index: 233371,
                parent_root:    0xc6e822d978ee3cf1f811389fc087e9020fc9aebb3be250579601cf57661d9d95,
                state_root:     0x145bf800cbd72dffb76cb3c8a45586c0632053d10af4c6163446c12d937c41b8,
                body_root:      0xe683ebcb97b578a72f9c30533a8fdf046a9473408fd3bde3c68f56308eddb922
            });
        return finalized_header;
    }

    function build_finality_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x03f0010000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0x20138281596673b75e115e00b445b078aceeb926d13de9ca847d862cb2564c1f;
        finality_branch[2] = 0xf5d713060e8a77425c6e350a7cda34e5b488c606deb3c873fd490dfc83c76ac5;
        finality_branch[3] = 0x6ecd6cbd81977588b8b788f51670363c4980dfb24358bba02cddbd672eddf455;
        finality_branch[4] = 0x52e3cf69b61aad545e242e2ef8a78df16127d59472d728d86401731350538ce6;
        finality_branch[5] = 0xa318f6d6418032efae3e4a269d72d04c291153b67b2390216087974cc5d3ca50;
        return finality_branch;
    }

    function build_next_sync_committee_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory next_sync_committee_branch = new bytes32[](5);
        // root next_sync_committee in attested_header
        next_sync_committee_branch[0] = 0xa36ba14c9ad227f9785a6b9ffd52d3b1f40a3fbd73e7445e18f70cac121612b4;
        next_sync_committee_branch[1] = 0x9820907666e8cdfa916cb110286263c0191cc8a71c59b3d16ffef8cbbb4b83b0;
        next_sync_committee_branch[2] = 0x6ecd6cbd81977588b8b788f51670363c4980dfb24358bba02cddbd672eddf455;
        next_sync_committee_branch[3] = 0x52e3cf69b61aad545e242e2ef8a78df16127d59472d728d86401731350538ce6;
        next_sync_committee_branch[4] = 0xa318f6d6418032efae3e4a269d72d04c291153b67b2390216087974cc5d3ca50;
        return next_sync_committee_branch;
    }

    function build_execution_payload() internal pure returns (ExecutionPayload memory) {
        return ExecutionPayload({
                 parent_hash:      0xbb762440415eda896064e4e8f9fcd1b74adbe4586726530acecd9b2106b0e688,
                 fee_recipient:    0x8dC847Af872947Ac18d5d63fA646EB65d4D99560,
                 state_root:       LATEST_EXECUTION_PAYLOAD_STATE_ROOT,
                 receipts_root:    0xef5f362b0f09407472505e9d0b7961980886397c011e377e8797db3b2cb6fdfd,
                 logs_bloom:       0x5a9e641747cd201c31d5d7111b08bc78f7e7b05665c25dea0175e002899a3f62,
                 prev_randao:      0xb126ec433144f3bdacc15ab6adf9805aa69841cbc9da30b2397d65db57094c3a,
                 block_number:     7738371,
                 gas_limit:        30000000,
                 gas_used:         29887283,
                 timestamp:        1665304416,
                 extra_data:       0x6c1af7064d349ef5be90d2e1a75c07f5f784e925bcda1f7a32e8003a6f7427a9,
                 base_fee_per_gas: 55,
                 block_hash:       0xe0f467253ab0ca0cbcf2d60e19fe9d9672eb547e5ef99b5fee7e7fbad3a109c8,
                 transactions:     0x000c92092b4515fc77f506734bdd78ff3b7413655284674e92ffbebc1ee853a8
             });
    }

    function build_beacon_block_body() internal pure returns (BeaconBlockBody memory) {
        return BeaconBlockBody({
             randao_reveal:      0xc307895482d9d180bfcc36bb3c60c7491120f1e71e002c59a820763fd8a62844,
             eth1_data:          0xe432e8cebdf0704e8ee73b79adc843d7a1841e0895ecf5beac8097e30579ad07,
             graffiti:           0x0000000000000000000000000000000000000000000000000000000000000000,
             proposer_slashings: 0x792930bbd5baac43bcc798ee49aa8185ef76bb3b44ba62b91d86ae569e4bb535,
             attester_slashings: 0x7a0501f5957bdf9cb3a8ff4966f02265f968658b7a9c62642cba1165e86642f5,
             attestations:       0xb7c162f3f51293b0ed700997585a8d3832cf44e14fdd450c6e1033b29e17651a,
             deposits:           0x792930bbd5baac43bcc798ee49aa8185ef76bb3b44ba62b91d86ae569e4bb535,
             voluntary_exits:    0x792930bbd5baac43bcc798ee49aa8185ef76bb3b44ba62b91d86ae569e4bb535,
             sync_aggregate:     0x2241a02ad04b01b7c6dfeb3d601c02bae83317e7e1085321ddfd8b42a5ddb6f9,
             execution_payload:  build_execution_payload()
        });
    }

    function sum(bytes32[2] memory x) internal pure returns (uint256) {
        return countSetBits(uint(x[0])) + countSetBits(uint(x[1]));
    }

    function test_sum_sync_committee_bits() public {
        bytes32[2] memory sync_committee_bits = [
            bytes32(0x7ffeefbfffbf7bffbff72efeff6ffdfeef37f9dfa7b41fdd3fbfeffdfffe67f6),
            bytes32(0xfdffbfdf7ffffffbebbfdfdfcfbefffb7ff4e8ffef7dbff759deff27fbbab7ff)
        ];
        assertEq(sum(sync_committee_bits), 420);
    }
}
