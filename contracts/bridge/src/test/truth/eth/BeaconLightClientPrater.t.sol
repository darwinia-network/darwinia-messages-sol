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


contract BeaconLightClientPraterTest is DSTest, BeaconLightClientUpdate, Bitfield, SyncCommitteePreset {
    bytes32 constant CURRENT_SYNC_COMMITTEE_ROOT = 0x4bcc8065b1462577a9971110aaa3ea5630ce3e6bc0ecb53e54777ce7d4a5e816;
    bytes32 constant GENESIS_VALIDATORS_ROOT = 0x043db0d9a83813551ee2f33450d23797757d430911a9320530ad8a0eabc43efb;

    BeaconLightClient lightclient;
    MockBLS bls;
    address self;
    function setUp() public {
        bls = new MockBLS();
        lightclient = new BeaconLightClient(
            address(bls),
            5431296,
            156599,
            0x6e6eb69b692ab61b4848c7d7ead6397b897a0544a4d90684e72026e1d3433efa,
            0xc04c27ea01b7e07136e0a9b697ff0fdcd6d88aad5f262953bf23e4586ae8104c,
            0x75f47fc8313ca967e1e81372b57309703b92d1f7e449fa8c1aa29106134c38d6,
            CURRENT_SYNC_COMMITTEE_ROOT,
            GENESIS_VALIDATORS_ROOT
        );
        self = address(this);
    }

    function test_constructor_args() public {}

    function test_import_next_sync_committee() public {
        FinalizedHeaderUpdate memory header_update = build_header_update();
        process_import_next_committee(header_update);
        bytes32 stored_next_sync_committee_root = lightclient.sync_committee_roots(header_update.finalized_header.beacon.slot/32/256 + 1);
        assertEq(hash_tree_root(sync_committee_case3()), stored_next_sync_committee_root);
        assert_finalized_header(header_update.finalized_header.beacon);
        assert_exection_payload(header_update.finalized_header.execution);
    }

    function test_import_finalized_header() public {
        FinalizedHeaderUpdate memory header_update = build_header_update();
        process_import_next_committee(header_update);
        FinalizedHeaderUpdate memory update = build_header_update1();
        lightclient.import_finalized_header(update);
        assert_finalized_header(update.finalized_header.beacon);
        assert_exection_payload(update.finalized_header.execution);
    }

    function test_hash_execution_payload() public {
        FinalizedHeaderUpdate memory update = build_header_update();
        assertEq(hash_tree_root(update.finalized_header.execution), 0x323b362b45977b46b6059b49ccbf2be1bdf57c119b0f1ec0efc9cb79a8532cb6);
    }

    function assert_finalized_header(BeaconBlockHeader memory finalized_header) internal {
        (uint64 slot, uint64 proposer_index, bytes32 parent_root, bytes32 state_root, bytes32 body_root) = lightclient.finalized_header();
        assertEq(uint(slot), finalized_header.slot);
        assertEq(uint(proposer_index), finalized_header.proposer_index);
        assertEq(parent_root, finalized_header.parent_root);
        assertEq(state_root, finalized_header.state_root);
        assertEq(body_root, finalized_header.body_root);
    }

    function assert_exection_payload(ExecutionPayloadHeader memory header) internal {
        uint256 block_number = lightclient.block_number();
        bytes32 merkle_root  = lightclient.merkle_root();
        assertEq(block_number, header.block_number);
        assertEq(merkle_root, header.state_root);
    }

    function process_import_next_committee(FinalizedHeaderUpdate memory header_update) internal {
        SyncCommitteePeriodUpdate memory sc_update = SyncCommitteePeriodUpdate({
            next_sync_committee: sync_committee_case3(),
            next_sync_committee_branch: build_next_sync_committee_branch()
        });
        lightclient.import_next_sync_committee(header_update, sc_update);
    }

    function build_header_update1() internal pure returns (FinalizedHeaderUpdate memory) {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x1298020000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0x71dc60eb4c834f6d6da05e3519fb30b7dad8200392096c08a73d7aae83f61932;
        finality_branch[2] = 0xd3b91174c0c90b13701df2a76bb382c6eae3e1f4f5ebf056a79d7c4550a0ce36;
        finality_branch[3] = 0x72cfa3a45568d4320651f616476738b20c2316ec0704c9aa70423769f3287735;
        finality_branch[4] = 0x12893a548d8e89d289169e6fe15ed4e112e6e6e777855750257b6a3af5ae7620;
        finality_branch[5] = 0x71c3adfd5bf78fe20b5d41a358f48af60788d93ba04cb44921e527f8a43cf18b;

        bytes32[] memory execution_branch1 = new bytes32[](4);
        execution_branch1[0] = 0xa10ef314b7cc705ac9d4460afd24ff7e5aa23391edafd1a81277a227954cb806;
        execution_branch1[1] = 0x336488033fe5f3ef4ccc12af07b9370b92e553e35ecb4a337a1b1c0e4afe1e0e;
        execution_branch1[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        execution_branch1[3] = 0x99e8db97877ee912a4c7707d6112e6e75a9891094bdbc4d600a16a9b89518009;

        bytes32[] memory execution_branch2 = new bytes32[](4);
        execution_branch2[0] = 0xe0cb19607540d626b2b717a7b89c3cdf099de40eb2b8e756d2c4bca790684bee;
        execution_branch2[1] = 0x336488033fe5f3ef4ccc12af07b9370b92e553e35ecb4a337a1b1c0e4afe1e0e;
        execution_branch2[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        execution_branch2[3] = 0x7eec4dce927f43e5a29b78c73a4e2dce5074ed4d6cba52173b580bb0ebca4c1e;

        return FinalizedHeaderUpdate({
            attested_header: LightClientHeader({
                beacon: BeaconBlockHeader({
                    slot:           5440166,
                    proposer_index: 115029,
                    parent_root:    0x13d9895650cefc00a52670fdc259fae8cf015d7eed24dcc4561dfb8d1e2f1096,
                    state_root:     0xf37cd1b2781a0439313b945c0c0255bf0cbe1fb679291def9c7e6eec5e96137a,
                    body_root:      0xb1dd8c95c71aac722f45530d6a1ddd19d49d9d554b50d1483e8aff7dd31f8029
                }),
                execution: ExecutionPayloadHeader({
                    parent_hash: 0x1c7c232c74366c8965617f58a1e81f8db361bbe87c8a1303737e0a13f9f6b351,
                    fee_recipient: 0xc6e2459991BfE27cca6d86722F35da23A1E4Cb97,
                    state_root: 0x4e8abf07cc78d0bb34e9e95d7e5495fe48f027b2984818d41395b3badd5461c2,
                    receipts_root: 0xb5efc8df4ef6204945769bb44aaed7f74e2dc0683874fdf95d45f769f4d6aa92,
                    logs_bloom: 0x270f4a87bf8de936d1a3964469cde44744432abcc84018d5bb5b96c10e88deee,
                    prev_randao: 0x903921ba16aad9da2d3dfdc161677c404c9327f0e187b5e4bea29c84b4d320e8,
                    block_number: 8848430,
                    gas_limit: 30000000,
                    gas_used: 15731735,
                    timestamp: 1681789992,
                    extra_data: 0x9707609c8f681aee747c8df1ac99cca57c4bd1f65d018d372ddf32a1e592daf5,
                    base_fee_per_gas: 390525,
                    block_hash: 0x1abc533e26518f9a05822d53ca72d6d15e599e50261069a3b4b0b995ce5b5a5b,
                    transactions_root: 0x16ee264ba4fc1789909e5bab1f457a47b7096dac7a6adc6104993cc113b174f8,
                    withdrawals_root: 0x9d8919556e8c3596f9dafaac262d097ad5be68920431ef8b46cb899884cbb396
                }),
                execution_branch: execution_branch1
            }),
            signature_sync_committee: sync_committee_case3(),
            finalized_header: LightClientHeader({
                beacon: BeaconBlockHeader({
                    slot:           5440064,
                    proposer_index: 241257,
                    parent_root:    0xdad993b039710f83fac114075bd3e4cd5308620c61bf6ec1e0fa384b967e35f6,
                    state_root:     0x7422093c63f32c9b0bd918bd855e0a6bea8cea2d30b283d57d9e4ea1749617f4,
                    body_root:      0x72c9d90f7bbb0895915d13f740c83f863acc1e58f8011ff9926d528a60f301f2
                }),
                execution: ExecutionPayloadHeader({
                    parent_hash: 0xb70f920bdfc867ebf0e1fe3b13965434f37113b88657cde176221807c9c229e2,
                    fee_recipient: 0x35ae1a321f54746004D8Ea72eBEe9d32785be4A0,
                    state_root: 0xe591381a351918930c454ba570024fac15090341968b91551b3776f276671cf2,
                    receipts_root: 0xe8d17ad354afcd1e6b49aa16628f8bdbca3f13e7ef38ca4f267063ab3dc7121c,
                    logs_bloom: 0x91eb00b99022498b7357f7358c7b56e47cb0d560a7987d107a929fa8a059495d,
                    prev_randao: 0x42473c4b84a99f5d086093e4a0e3edbd69237490525b9c76c21792195107d419,
                    block_number: 8848355,
                    gas_limit: 30000000,
                    gas_used: 16388925,
                    timestamp: 1681788768,
                    extra_data: 0xd6c887f9b24c560597973c180ce5dd9f72153e092b08758e7da1471f360840c3,
                    base_fee_per_gas: 160845,
                    block_hash: 0xbe58b48696fea3a792ff3a5250e04f882625eadb235c9fcc356173c85d7f321a,
                    transactions_root: 0xe274d951b5071afa814e31d79c71be74e41fecdf8523c4aafa551cb9adc9013c,
                    withdrawals_root: 0xfb130ffc1441372cf29b4be3ab1150d62ff97695dac9999038bd40de4113ce18
                }),
                execution_branch: execution_branch2
            }),
            finality_branch: finality_branch,
            sync_aggregate: SyncAggregate({
                sync_committee_bits:[
                    bytes32(0x07ddaffedf9ee77a5fe8febbffbffbefbb7ffffff71d36feb6f4ef7557fffcff),
                    bytes32(0xdbeb6df6feffafeac967e53efb99dffccbfff5fbbe6d765f594cffbdf3f7fbff)
                ],
                sync_committee_signature: hex'95948e93847f00ab4bc47892b8250049393a782bf51c6f0f8219cd0dd4793640e7ba972f5ea0179ada9bf3248e97a68219c1a968b4859a86e576dbd66faaa4c2d48427ed67ff26c579adea5bae5173da293e9d7a301b633aae3382140d380a29'
            }),
            fork_version: 0x03001020,
            signature_slot: 5440167
        });
    }

    function build_execution_branch0() internal pure returns (bytes32[] memory) {
        bytes32[] memory execution_branch = new bytes32[](4);
        execution_branch[0] = 0x258a1fac1fd0f9c313c7533c2ab456aa4dd55f4d05447d95fc5a2f6f0930b4ea;
        execution_branch[1] = 0x336488033fe5f3ef4ccc12af07b9370b92e553e35ecb4a337a1b1c0e4afe1e0e;
        execution_branch[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        execution_branch[3] = 0xb06dccb3a8eba043bb0b230b26d92a6276f925d551c4f0b8d47282ccaeb52561;
        return execution_branch;
    }

    function build_execution_branch1() internal pure returns (bytes32[] memory) {
        bytes32[] memory execution_branch = new bytes32[](4);
        execution_branch[0] = 0xbd2bf9939680435cac3c990592eab5707274f907aa5cf4d51d0b629ec6dff5a3;
        execution_branch[1] = 0x336488033fe5f3ef4ccc12af07b9370b92e553e35ecb4a337a1b1c0e4afe1e0e;
        execution_branch[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        execution_branch[3] = 0xb850949b485c4e4748756c52b963c2d94419159aeb733b784ac5ddfb4cfca658;
        return execution_branch;
    }

    function build_finality_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x2b97020000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0x68094b86a4b1aa388d4fa35f1d6f9f9641ee81d066f8302f6622868896ca872d;
        finality_branch[2] = 0xfa8d3416b207fd3d5afd29ea16361f95736a5edcc62d550c40c7915e3d811c13;
        finality_branch[3] = 0xe7fcbef3ebfe4659c1e2cbe04a0877e23c2cd1cdcc16d308815a87f179cf62bb;
        finality_branch[4] = 0x543002c6926c9e101079f4fb0ee36b71d79d45d82e7635d7f01c0b36184bf77a;
        finality_branch[5] = 0x316c8f1be6eb127ab8ee55ad99ae855b45d1c07fe5451f9e2054cac30b57892a;
        return finality_branch;
    }

    function build_header_update() internal pure returns (FinalizedHeaderUpdate memory) {
        return FinalizedHeaderUpdate({
            attested_header: LightClientHeader({
                beacon: BeaconBlockHeader({
                    slot:           5432749,
                    proposer_index: 373898,
                    parent_root:    0x6a5a5275ef4d170c40aaf9d4b89b376cdf5f44697af34b93499e2011ac281ca2,
                    state_root:     0x4464f0ef276888bc833419c1769e86244086363f56cb787da034c4f26453d7ab,
                    body_root:      0x681c106424c75044b06479b2b7871a8010a656961c0bf3379143e620cfad1883
                }),
                execution: ExecutionPayloadHeader({
                    parent_hash:       0xe723261fb685257b39a7dc7b506e473e08962ea5afc886669d1c55d199a86059,
                    fee_recipient:     0x2d1A0d741443eD1d52547D6bf6b04Ee4743f095B,
                    state_root:        0x560e16b22b69cf061c5d00aef0876ab171739deec5cfed6e11a284d5a159f4d1,
                    receipts_root:     0x73e9731825d5f76b2e75cde90a782adb14c30e04c6bc507f56b21804f2631aec,
                    logs_bloom:        0xe1d0ffb956f140e248a3281e893f96c196b2c341afd739a16eabf61ae1bbc69a,
                    prev_randao:       0x038bcd65322bfde62e459a2151127680c5e8c9d5f3a718eaa338ddcb49cf18cf,
                    block_number:      8842880,
                    gas_limit:         30000000,
                    gas_used:          29964667,
                    timestamp:         1681700988,
                    extra_data:        0xebd940a554baa1963cd1d00e6f94ccdd85fa52c8092d207b7d566de6a840834d,
                    base_fee_per_gas:  7449434,
                    block_hash:        0x96bdb0ac6829f04cb9086cf52e21f46fae83ab74aca8e371313847cc7211123e,
                    transactions_root: 0x6fc65bbcbb33bfc4360ea847265cc12afea01ff18c482b1cdb59205b9673d18a,
                    withdrawals_root:  0x72edce17766e27da0503f770876a4b417ec4018287c8dcc63ce3cbce5dc56cd6
                }),
                execution_branch: build_execution_branch0()
            }),
            signature_sync_committee: sync_committee_case2(),
            finalized_header: LightClientHeader({
                beacon: BeaconBlockHeader({
                    slot:           5432672,
                    proposer_index: 191656,
                    parent_root:    0x54ea52e2c0b82585c5d26ba29ea44ec90d9ab3772ac9b514ee4eb72fefcdf197,
                    state_root:     0x0f698888156f9dc4fbd96b41b87f3aed6d024b87dd22b5cac3d30b1ea999e143,
                    body_root:      0x6ad2ecabf6517db01f0616ab52fb0563a0f22f46112393e16a9fe4b4259b57bc
                }),
                execution: ExecutionPayloadHeader({
                    parent_hash: 0xd2672a40e8056953012165c9a1d2a1861699af6f9d0a036085bb1c6fdb3693af,
                    fee_recipient: 0x455E5AA18469bC6ccEF49594645666C587A3a71B,
                    state_root: 0x046a96b74460971ed01a7321548b768a5f6064cc8cb1c5f89c3e73eba50f9801,
                    receipts_root: 0x8f3dafa2e2176a7bf6bb9a12a91d4719b591522d68e5348d45cba4b3dbe01e03,
                    logs_bloom: 0x9c127be96aa7ba288f5d8c755971040a413b90773dac019470d7c21d4beae344,
                    prev_randao: 0x6cd18c9764a62748ee6031788641bb51b1090f635c1e9f65ad6e206446b63518,
                    block_number: 8842824,
                    gas_limit: 30000000,
                    gas_used: 19067818,
                    timestamp: 1681700064,
                    extra_data: 0xebd940a554baa1963cd1d00e6f94ccdd85fa52c8092d207b7d566de6a840834d,
                    base_fee_per_gas: 5107685,
                    block_hash: 0x863fe062e91555c36a327e51dae6df9f1f9f7dd5b44b1109aba207f6cb532cec,
                    transactions_root: 0xc56e3aa9fa79fa84ab37394d35d30bb6e5acbb5be01741dd2df33d4f4ac4cbce,
                    withdrawals_root: 0xdcf466ef233630fa7f29b09309ca7413e4c6c3f8b1a7d34d64de03503c64203e
                }),
                execution_branch: build_execution_branch1()
            }),
            finality_branch: build_finality_branch(),
            sync_aggregate: SyncAggregate({
                sync_committee_bits:[
                    bytes32(0xbf6fbfffffdfaecf0deeffff675ffefffdffedfaffeff7bfafd7babf73f6fdff),
                    bytes32(0xffdffc77afbfb7ffef7bdff41df77afffcf9fff3ffff7db3bfeffbfbf5ff84fb)
                ],
                sync_committee_signature: hex'a78b70b91b93c5b6a37b359d3e3bef8b6c5bceefc5ae776e87cb736a80533e03ac65e7807c00a21d67a4224bf6139b05054a95338db8d09119f1b8c973acaefbe53ba599315125b1207d696b50376da73a17dd8cdbccf1aa3f002d8f347ec8f9'
            }),
            fork_version: 0x03001020,
            signature_slot: 5432750
        });
    }

    function build_next_sync_committee_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory next_sync_committee_branch = new bytes32[](5);
        // root next_sync_committee in attested_header
        next_sync_committee_branch[0] = 0x4bcc8065b1462577a9971110aaa3ea5630ce3e6bc0ecb53e54777ce7d4a5e816;
        next_sync_committee_branch[1] = 0x5f2640be1ce4b023d2ba9217849dd782a2c81650b2667a634993c83b9e47c51b;
        next_sync_committee_branch[2] = 0xe7fcbef3ebfe4659c1e2cbe04a0877e23c2cd1cdcc16d308815a87f179cf62bb;
        next_sync_committee_branch[3] = 0x543002c6926c9e101079f4fb0ee36b71d79d45d82e7635d7f01c0b36184bf77a;
        next_sync_committee_branch[4] = 0x316c8f1be6eb127ab8ee55ad99ae855b45d1c07fe5451f9e2054cac30b57892a;
        return next_sync_committee_branch;
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
