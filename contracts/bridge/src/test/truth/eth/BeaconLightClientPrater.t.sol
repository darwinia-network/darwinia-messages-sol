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
import "../../../utils/Bitfield.sol";
import "../../spec/SyncCommittee.t.sol";
import "../../../truth/eth/BeaconLightClient.sol";
import "../../../truth/eth/ExecutionLayer.sol";

contract BeaconLightClientPraterTest is DSTest, Bitfield, SyncCommitteePreset {
    bytes32 constant CURRENT_SYNC_COMMITTEE_ROOT = 0x21053f2ba6bbb6c6d452697ea35aa1c77edfb48aae52612169d01290d90f7155;
    bytes32 constant GENESIS_VALIDATORS_ROOT = 0x043db0d9a83813551ee2f33450d23797757d430911a9320530ad8a0eabc43efb;
    bytes32 constant LATEST_EXECUTION_PAYLOAD_STATE_ROOT = 0xe55ce819dcd715afb77bac000eb6495ea0dc93e3380501100718403c063a70b0;

    BeaconLightClient lightclient;
    ExecutionLayer executionlayer;
    MockBLS bls;
    address self;

    function setUp() public {
        bls = new MockBLS();
        lightclient = new BeaconLightClient(
            address(bls),
            651232,
            86325,
            0x13189ed59789d8c28c9e4f8aed4494979075cf3c0a1ee9fd03f93816f65bbe16,
            0xd29f11a73f0207a356e38ad5dccdaa2fdf6c94aa9c51d34e6ca29ce9dbdd6550,
            0x6a52c3e5c4d195607035457f4263b3a3a653d9b143bc73bef5ca5c1154b5c02d,
            CURRENT_SYNC_COMMITTEE_ROOT,
            GENESIS_VALIDATORS_ROOT
        );
        executionlayer = new ExecutionLayer(address(lightclient));
        self = address(this);
    }

    function test_constructor_args() public {

    }

    function test_import_next_sync_committee() public {
        BeaconBlockHeader memory finalized_header = build_finalized_header();
        process_import_finalized_header(finalized_header);
        bytes32[] memory next_sync_committee_branch = build_next_sync_committee_branch();
        BeaconLightClient.SyncCommitteePeriodUpdate memory update = BeaconLightClient.SyncCommitteePeriodUpdate({
            next_sync_committee: sync_committee_case4(),
            next_sync_committee_branch: next_sync_committee_branch
        });
        lightclient.import_next_sync_committee(update);
        bytes32 stored_next_sync_committee_root = lightclient.sync_committee_roots(80);
        assertEq(hash_tree_root(sync_committee_case4()), stored_next_sync_committee_root);
    }

    function test_import_latest_execution_payload_state_root() public {
        BeaconBlockHeader memory finalized_header = build_finalized_header();
        process_import_finalized_header(finalized_header);
        bytes32[] memory latest_execution_payload_state_root_branch = build_latest_execution_payload_state_root_branch();
        ExecutionLayer.ExecutionPayloadStateRootUpdate memory update = ExecutionLayer.ExecutionPayloadStateRootUpdate({
            latest_execution_payload_state_root: LATEST_EXECUTION_PAYLOAD_STATE_ROOT,
            latest_execution_payload_state_root_branch: latest_execution_payload_state_root_branch
        });
        executionlayer.import_latest_execution_payload_state_root(update);
        assertEq(executionlayer.merkle_root(), LATEST_EXECUTION_PAYLOAD_STATE_ROOT);
    }

    function test_import_finalized_header() public {
        BeaconBlockHeader memory finalized_header = build_finalized_header();
        process_import_finalized_header(finalized_header);
        assert_finalized_header(finalized_header);
    }

    function assert_finalized_header(BeaconBlockHeader memory finalized_header) public {
        (uint64 slot, uint64 proposer_index, bytes32 parent_root, bytes32 state_root, bytes32 body_root) = lightclient.finalized_header();
        assertEq(uint(slot), finalized_header.slot);
        assertEq(uint(proposer_index), finalized_header.proposer_index);
        assertEq(parent_root, finalized_header.parent_root);
        assertEq(state_root, finalized_header.state_root);
        assertEq(body_root, finalized_header.body_root);
    }

    function process_import_finalized_header(BeaconBlockHeader memory finalized_header) public {
        bytes32[] memory finality_branch = build_finality_branch();

        BeaconLightClient.FinalizedHeaderUpdate memory update = BeaconLightClient.FinalizedHeaderUpdate({
            attested_header: BeaconBlockHeader({
                slot: 651365,
                proposer_index: 43797,
                parent_root: 0x30d7a76229d0b814b62b67f32600b4151c23a9e6fc20d792b93d0d29c3f58e1c,
                state_root: 0xe5991d8aba197cc483b381bf29602fc9f32b602c5198cf268eb3fe2946b5942f,
                body_root: 0x1919d319f54f9e0b5de79fc86f9494ae651e27698488b211acccbd4da32ba3be
            }),
            signature_sync_committee: sync_committee_case3(),
            finalized_header: finalized_header,
            finality_branch: finality_branch,
            sync_aggregate: BeaconLightClient.SyncAggregate({
                sync_committee_bits:[
                    bytes32(0xf7fffeefebd6ff6faf7ffffd7dfffffe6ff6bfbfffdedefffffff7fff5f77dac),
                    bytes32(0xe7fffb7fddffaefdfffffeffefffbdfffffbe6fb5fffb7fefd7f3fffffffbffb)
                ],
                sync_committee_signature: hex'afef0939a9e716283e11070e716a96cbeab8af6e4d695bf3366ea9d4dcb5aaa24841da1f7c9534d6aafe2bf1d79ea2b10a7a2748d9c3b602eb5f364c7fac1a2b9fa986d4bb075d3d6a68ad1186a2a46f2359ee8c27ad7726703969255c6dcfdd'
            }),
            fork_version: 0x70000071,
            signature_slot: 651366
        });
        lightclient.import_finalized_header(update);
    }

    function build_finalized_header() internal pure returns (BeaconBlockHeader memory) {
        BeaconBlockHeader memory finalized_header = BeaconBlockHeader({
                slot: 651296,
                proposer_index: 75122,
                parent_root: 0x8df1fc9b14535dc274a25910a35311696cb185f6b3a6214dc454c0e1120b9304,
                state_root: 0x582d324ed86245abb2f715b796e02781952762d1ec75fc51ccee70b260c592be,
                body_root: 0xcd4bdfe82d423c4270b68f56c9a0a805adb133519c53e0d0c4c33820c5bd407d
        });
        return finalized_header;
    }

    function build_finality_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x814f000000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0xa9735d8aacd3002f679d93725445b97dc34b5e41272b4c85326c8b143d920686;
        finality_branch[2] = 0x1a4e08f19e3824aea37f5242cb84b4fb028dfe330d079eab0bd9bbf797ababdd;
        finality_branch[3] = 0x79da7a757abf525a5dabd1c6af0b9bcae30af24887c4b585f27cdc8e57a82ff7;
        finality_branch[4] = 0x78fc8fd38e5910dc692176369a93e65b1c416dcd59dff970b10de5e7e7860920;
        finality_branch[5] = 0x9ac6f0aef5fee862aa7138e86cb18c7e9dcf92b7e1dee90802117e39742486fd;
        return finality_branch;
    }

    function build_next_sync_committee_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory next_sync_committee_branch = new bytes32[](5);
        next_sync_committee_branch[0] = 0x21053f2ba6bbb6c6d452697ea35aa1c77edfb48aae52612169d01290d90f7155;
        next_sync_committee_branch[1] = 0xd32bbe1442d4b417f896e794c3a3d3e2a672bbd66a6fb7204d3c4e63fee33ef0;
        next_sync_committee_branch[2] = 0xf7cdf4e74455d9925fff6f90e16653113b337eebe178c21b1da1f5d1e6611751;
        next_sync_committee_branch[3] = 0x38a2c83d926d0cc5521cb4d36d096c79e453d0214bcd64d68b0423f2c48eedad;
        next_sync_committee_branch[4] = 0x5e97dd766bf30ee49745229a3790470e642f2dd3b3c8ce13e3f7b4bc6e4b3205;
        return next_sync_committee_branch;
    }

    function build_latest_execution_payload_state_root_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory latest_execution_payload_state_root_branch = new bytes32[](9);
        latest_execution_payload_state_root_branch[0] = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
        latest_execution_payload_state_root_branch[1] = 0x89fbf2edd4374bf78f47f697abedbbb3063b0948d4c2c69a715d2664f45ef943;
        latest_execution_payload_state_root_branch[2] = 0xb2aced9d410d818440966483a6f23f045146aa4a4d5f25918bff488af24a285f;
        latest_execution_payload_state_root_branch[3] = 0x60187b4f101a1533632d9c730a1a419f6b61de9a412e2e33ce18b8f041e0580c;
        latest_execution_payload_state_root_branch[4] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        latest_execution_payload_state_root_branch[5] = 0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b;
        latest_execution_payload_state_root_branch[6] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        latest_execution_payload_state_root_branch[7] = 0x221207ac8656532897f09f6e17c05fa2ef1d32cf1cd6187b79c5d0fa7c4ba7f4;
        latest_execution_payload_state_root_branch[8] = 0x5e97dd766bf30ee49745229a3790470e642f2dd3b3c8ce13e3f7b4bc6e4b3205;
        return latest_execution_payload_state_root_branch;
    }

    function sum(bytes32[2] memory x) internal pure returns (uint256) {
        return countSetBits(uint(x[0])) + countSetBits(uint(x[1]));
    }

    function test_sum_sync_committee_bits() public {
        bytes32[2] memory sync_committee_bits = [
            bytes32(0xf7fffeefebd6ff6faf7ffffd7dfffffe6ff6bfbfffdedefffffff7fff5f77dac),
            bytes32(0xe7fffb7fddffaefdfffffeffefffbdfffffbe6fb5fffb7fefd7f3fffffffbffb)
        ];
        assertEq(sum(sync_committee_bits), 445);
    }
}
