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


contract BeaconLightClientMainnetTest is DSTest, Bitfield, SyncCommitteePreset {
    bytes32 constant CURRENT_SYNC_COMMITTEE_ROOT = 0x5e1c2e0e1f73857bdb258e7913387d0fbd14894896e2715b69189eaed7919992;
    bytes32 constant GENESIS_VALIDATORS_ROOT = 0x4b363db94e286120d76eb905340fdd4e54bfe9f06bf33ff6cf5ad27f511bfe95;
    bytes32 constant LATEST_EXECUTION_PAYLOAD_STATE_ROOT = 0xc22665bddd71c249eff6dea84255918cc4d0537ecceaa9348419231a64259beb;

    BeaconLightClient lightclient;
    ExecutionLayer executionlayer;
    MockBLS bls;
    address self;

    function setUp() public {
        bls = new MockBLS();
        lightclient = new BeaconLightClient(
            address(bls),
            4866432,
            170382,
            0x7fdc0fc420272a0eb3d2de0dc7cf9defbcee0316b346a56afa156f5b2da93a1f,
            0xed4f9746917d25ec8a163d7fb3e95edd50769b953d8f65cff4662469f4d34776,
            0xa16b851ed3d6e03e10fd3ac6bd617b0062702759daa59607e2f42d4441ba802b,
            CURRENT_SYNC_COMMITTEE_ROOT,
            GENESIS_VALIDATORS_ROOT
        );
        executionlayer = new ExecutionLayer(address(lightclient));
        self = address(this);
    }

    function test_constructor_args() public {}

    function test_update_sync_committee_period() public {
        BeaconLightClient.FinalizedHeaderUpdate memory header_update = build_header_update();
        bytes32[] memory next_sync_committee_branch = build_next_sync_committee_branch();
        BeaconLightClient.SyncCommitteePeriodUpdate memory sc_update = BeaconLightClient.SyncCommitteePeriodUpdate({
            next_sync_committee: sync_committee_case5(),
            next_sync_committee_branch: next_sync_committee_branch
        });
        lightclient.update_sync_committee_period(header_update, sc_update);
        bytes32 stored_next_sync_committee_root = lightclient.sync_committee_roots(595);
        assertEq(hash_tree_root(sync_committee_case5()), stored_next_sync_committee_root);
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
        assertEq(hash_tree_root(body), 0x319c41b0a25994b5ef50d5beee9afb860bd12637b4018c03f4537f6ad5879be7);
    }

    function test_hash_execution_payload() public {
        ExecutionPayload memory payload = build_execution_payload();
        assertEq(hash_tree_root(payload), 0x7dca0ead2432d173e500e04c2089681bc06abc66c91b5b5e4c15d04a7f278810);
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
        finality_branch[0] = 0xeb52020000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0xbdb6b1978a1b3a5f98284a20ab3c7f1846a01680cec63a808e1e5b86c9e17e06;
        finality_branch[2] = 0x62481c2b08a0f64bf98a05b233db94ead81bb614b84efc121a91e38e738876e1;
        finality_branch[3] = 0x06f9d0ca5747279fe92d3bfe0ddcc2086d12cdcb3525a08e9c098855046bb6cd;
        finality_branch[4] = 0x2880db0f7f2281ef35342a53173c21215810354033d0c1d40813898ea299b8a2;
        finality_branch[5] = 0x7e0ba77ff7042a877d38eb195f4cf435afab2b5567b649bb1755c21c9cb8215e;

        BeaconLightClient.FinalizedHeaderUpdate memory update = BeaconLightClient.FinalizedHeaderUpdate({
            attested_header: BeaconBlockHeader({
                slot:           4873635,
                proposer_index: 263940,
                parent_root:    0xcf75744e4b8f2192da04e2607c9aed6f3cb775f58f5fb9a4875c89432fda671d,
                state_root:     0x0d94fa3895c9a8d4da30d26db908c17395eb0acfda687efa82c8220444b66752,
                body_root:      0x2fb9674d3a1741992cdb626d57319205a4736ed23f7a1e7260bd10463b0676e5
            }),
            signature_sync_committee: sync_committee_case4(),
            finalized_header: build_finalized_header1(),
            finality_branch: finality_branch,
            sync_aggregate: BeaconLightClient.SyncAggregate({
                sync_committee_bits:[
                    bytes32(0xffffff7ffffffffffffffffffff7ffffffffffffffffffffffffffffffffffff),
                    bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbf)
                ],
                sync_committee_signature: hex'8e5a3a3d242062a60e804488c6117b2224a2ae7b91159a299c4b5e4467e28a3cd86b18d45a65c0237241d09b64473f6711e1d5d94ae2fe0d4dfe8ee5df8660e41f8f0038debbcac0b3fc81da9a23d9f7121b8a6539c6be7afdc371f361b7da87'
            }),
            fork_version: 0x02000000,
            signature_slot: 4873636
        });
        lightclient.import_finalized_header(update);
    }

    function build_header_update() internal pure returns (BeaconLightClient.FinalizedHeaderUpdate memory) {
        return BeaconLightClient.FinalizedHeaderUpdate({
            attested_header: BeaconBlockHeader({
                slot:           4866499,
                proposer_index: 83890,
                parent_root:    0xc73b9e14d7b45cfc4f4b971932cde076ecdfa29151295d8ad040c0ff28fb4209,
                state_root:     0x6adca15ef860fb683e3e4441a72e4565140839d627da9eabf3be6c287a8607a1,
                body_root:      0x6bd140aaac830c978644239867b2661de48875fcddbf8778402568fb36af8c28
            }),
            signature_sync_committee: sync_committee_case4(),
            finalized_header: build_finalized_header(),
            finality_branch: build_finality_branch(),
            sync_aggregate: BeaconLightClient.SyncAggregate({
                sync_committee_bits:[
                    bytes32(0xffffff7ffffffffffffffffffff7ffffffffffffffffffffffffffffffffffff),
                    bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbf)
                ],
                sync_committee_signature: hex'aefba53126c456bd9680f57c827edc84e3552c716f6e2c523b147fdf02862286bda1c8fd3d4931e7399aab541eca94800fe166cb6c5fd6dbb3acf18a87d4c4f77e86d5edc01245a5270838e713c4ed352bef0ba90b1164e903198a5ff0550a27'
            }),
            fork_version: 0x02000000,
            signature_slot: 4866500
        });
    }
    function build_finalized_header() internal pure returns (BeaconBlockHeader memory) {
        BeaconBlockHeader memory finalized_header = BeaconBlockHeader({
                slot:           4866432,
                proposer_index: 170382,
                parent_root:    0x7fdc0fc420272a0eb3d2de0dc7cf9defbcee0316b346a56afa156f5b2da93a1f,
                state_root:     0xed4f9746917d25ec8a163d7fb3e95edd50769b953d8f65cff4662469f4d34776,
                body_root:      0xa16b851ed3d6e03e10fd3ac6bd617b0062702759daa59607e2f42d4441ba802b
        });
        return finalized_header;
    }

    function build_finalized_header1() internal pure returns (BeaconBlockHeader memory) {
        BeaconBlockHeader memory finalized_header = BeaconBlockHeader({
                slot:           4873568,
                proposer_index: 149730,
                parent_root:    0xbc113a16868ad00ae4ee29790a0d4f2cbfb69c96d4361f0585f55e264a24e3f6,
                state_root:     0xe9f79e81504426ea4b83a70f555d640945317e8524638ff460f9ed82ca9d005d,
                body_root:      0x319c41b0a25994b5ef50d5beee9afb860bd12637b4018c03f4537f6ad5879be7
            });
        return finalized_header;
    }

    function build_finality_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x0c52020000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0x786f3ed136c994b50457add7405a3f325870dd099da95acb1f61e0cba94f34dd;
        finality_branch[2] = 0x62481c2b08a0f64bf98a05b233db94ead81bb614b84efc121a91e38e738876e1;
        finality_branch[3] = 0x4cb38736624bbcedf566de8edfcfbd8aebb74f4245ce6373394df56e345dbd34;
        finality_branch[4] = 0x97358b24f931c32eff8df92fa64d2ee7a12f5ce7ad7be7fe7452459c320a243b;
        finality_branch[5] = 0x52dae3de37b3b548d764c3a17fce84e89265f21c3c4b9a7415b64a186da99a0a;
        return finality_branch;
    }

    function build_next_sync_committee_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory next_sync_committee_branch = new bytes32[](5);
        // root next_sync_committee in finalized_header
        next_sync_committee_branch[0] = 0x5e1c2e0e1f73857bdb258e7913387d0fbd14894896e2715b69189eaed7919992;
        next_sync_committee_branch[1] = 0x86697ecd7bdecc40e33db367f2a92490ce0a8175d0b74440e4113555cc3fdc50;
        next_sync_committee_branch[2] = 0x0342cdec2e28897ac5e14a488838cf4c48e164812d877f5525e016dc6ae81a02;
        next_sync_committee_branch[3] = 0x8e880b85e14ba57a3b6bb1382719d86956a4234473d476f967580cbe53a323d6;
        next_sync_committee_branch[4] = 0x17a795c3c096ae8ae43736fc4a66d2c632af7dcb0135ad411bfecf71daebf58b;

        // root next_sync_committee in attested_header
        // next_sync_committee_branch[0] = 0x5e1c2e0e1f73857bdb258e7913387d0fbd14894896e2715b69189eaed7919992;
        // next_sync_committee_branch[1] = 0x8de9dbbdeea897ced54853e36f67f4bc3a64b9c319f3124c847c3c919077259b;
        // next_sync_committee_branch[2] = 0x4cb38736624bbcedf566de8edfcfbd8aebb74f4245ce6373394df56e345dbd34;
        // next_sync_committee_branch[3] = 0x97358b24f931c32eff8df92fa64d2ee7a12f5ce7ad7be7fe7452459c320a243b;
        // next_sync_committee_branch[4] = 0x52dae3de37b3b548d764c3a17fce84e89265f21c3c4b9a7415b64a186da99a0a;
        return next_sync_committee_branch;
    }

    function build_execution_payload() internal pure returns (ExecutionPayload memory) {
        return ExecutionPayload({
                 parent_hash:      0x9e6f788b61580956fb9d4e1cbe914a1c8972178ad0759a95dd0110d1932dc429,
                 fee_recipient:    0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5,
                 state_root:       LATEST_EXECUTION_PAYLOAD_STATE_ROOT,
                 receipts_root:    0xccc44c6c8092b7613abbd129e906388241532883c8e1acac2e8f3682966b0caf,
                 logs_bloom:       0x1c9822a8043215786d7e9e9235522ef3b7d8c5ea7e9b4ad876e08a186fd91c6b,
                 prev_randao:      0x8f07bbb2684311c49641c0ca352b73e172268786d2956d923c0f03509a191d10,
                 block_number:     15709572,
                 gas_limit:        30000000,
                 gas_used:         10457644,
                 timestamp:        1665306839,
                 extra_data:       0xd77cd27fad374ee5b9ad6670e15de0bd12de0512106f7d7071f31aa5fde432ae,
                 base_fee_per_gas: 28594991293,
                 block_hash:       0xaa47421ea334e47a3b09b6e641526b8dbf06623734ec8356d49f0c1dab03a92d,
                 transactions:     0x29c597cb90a68586993597e2eb49b069747ba69682e0305440f61a95975a5f29
             });
    }

    function build_beacon_block_body() internal pure returns (BeaconBlockBody memory) {
        return BeaconBlockBody({
             randao_reveal:      0x3d28b5038113b792eaa5e9b17add40d7669134d215e380a0156af66b23c8cc99,
             eth1_data:          0x7a56e61cac5142dd133ef066cd295cd7f049ac7b4a8f62639ef8eec84260d754,
             graffiti:           0x626c6f636b736361706500000000000000000000000000000000000000000000,
             proposer_slashings: 0x792930bbd5baac43bcc798ee49aa8185ef76bb3b44ba62b91d86ae569e4bb535,
             attester_slashings: 0x7a0501f5957bdf9cb3a8ff4966f02265f968658b7a9c62642cba1165e86642f5,
             attestations:       0x698244dadde586ca6d82095f24756680ee3fe7bccc77def57b5937d44f695669,
             deposits:           0x792930bbd5baac43bcc798ee49aa8185ef76bb3b44ba62b91d86ae569e4bb535,
             voluntary_exits:    0x792930bbd5baac43bcc798ee49aa8185ef76bb3b44ba62b91d86ae569e4bb535,
             sync_aggregate:     0xcd32f594096dd18c1d261eb08629564bad955c5c4fd894ce9c1a3d47e373f3ff,
             execution_payload:  build_execution_payload()
        });
    }

    function sum(bytes32[2] memory x) internal pure returns (uint256) {
        return countSetBits(uint(x[0])) + countSetBits(uint(x[1]));
    }

    function test_sum_sync_committee_bits() public {
        bytes32[2] memory sync_committee_bits = [
            bytes32(0xffffff7ffffffffffffffffffff7ffffffffffffffffffffffffffffffffffff),
            bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbf)
        ];
        assertEq(sum(sync_committee_bits), 509);
    }
}
