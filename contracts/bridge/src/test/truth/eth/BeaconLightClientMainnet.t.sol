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


contract BeaconLightClientMainnetTest is DSTest, BeaconLightClientUpdate, Bitfield, SyncCommitteePreset {
    bytes32 constant CURRENT_SYNC_COMMITTEE_ROOT = 0x344e99e6b29e1ffa0481053f25004cd8a0e0417804f3a22eaecb9e0d2948fb70;
    bytes32 constant GENESIS_VALIDATORS_ROOT = 0x4b363db94e286120d76eb905340fdd4e54bfe9f06bf33ff6cf5ad27f511bfe95;

    BeaconLightClient lightclient;
    MockBLS bls;
    address self;
    function setUp() public {
        bls = new MockBLS();
        lightclient = new BeaconLightClient(
            address(bls),
            6242304,
            371683,
            0x16f93626bc460e8449b5b905cf3584aa5ba4800ab39faa00b314bd384859904b,
            0x40594ba8043186666a95a0bbe61dfa98abdb918822f85524c18cd6d43e47aa47,
            0xbce8b928647016041dc771d82245b76ffeb0f07cc8d685acb9c22244df7189f3,
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
        assertEq(hash_tree_root(sync_committee_case5()), stored_next_sync_committee_root);
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
        assertEq(hash_tree_root(update.finalized_header.execution), 0x3134fcfa97ada30b4891ab9d1a8ffd875362efc4f8b76665ca7bc11052da61d4);
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
            next_sync_committee: sync_committee_case5(),
            next_sync_committee_branch: build_next_sync_committee_branch()
        });
        lightclient.import_next_sync_committee(header_update, sc_update);
    }

    function build_header_update1() internal pure returns (FinalizedHeaderUpdate memory) {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0xa8fa020000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0xb0cdaeec94c288483bd1bc60c983a2245c13aa832dc22539b198e9f22421142a;
        finality_branch[2] = 0xd2dfabb68f046bea102015a3566d0191b0c74ddad25f3d26149780bb54f001db;
        finality_branch[3] = 0xfd47de54e644dc644c9900702e4ffa7915a7eb5486ca158929c57513ba86b1c0;
        finality_branch[4] = 0x0b47f0ab8ebc30ed1c790476df32e66a5c7f4784c58e49da1af8b1eee722f22b;
        finality_branch[5] = 0xf726062689d64ff662061d8f7d8e7ab732ef65bfd166a585a8bf41020462627a;

        bytes32[] memory execution_branch1 = new bytes32[](4);
        execution_branch1[0] = 0x519ed81bca959f2a0ee362b99f1282bc4e649c4fd7c2c8231afd9849d7984a30;
        execution_branch1[1] = 0x336488033fe5f3ef4ccc12af07b9370b92e553e35ecb4a337a1b1c0e4afe1e0e;
        execution_branch1[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        execution_branch1[3] = 0xca362aebdc02078dea35106622ad3bb91747f97a0cbeebca57242e63388b70ff;

        bytes32[] memory execution_branch2 = new bytes32[](4);
        execution_branch2[0] = 0xb4ca6948d7a4aaa8ab59ff5b31188a9b97825831ed02563fa562aea439d218a7;
        execution_branch2[1] = 0x336488033fe5f3ef4ccc12af07b9370b92e553e35ecb4a337a1b1c0e4afe1e0e;
        execution_branch2[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        execution_branch2[3] = 0xc3a9066164d0583bf01d9c74ff0b2809096434008419525cf90b6f20a6703ba0;

        return FinalizedHeaderUpdate({
            attested_header: LightClientHeader({
                beacon: BeaconBlockHeader({
                    slot:           6247770,
                    proposer_index: 472580,
                    parent_root:    0x1a2a625af3392132e9b4d64b681e0ae259e32074c02e1e74bcd52eb3b65f4060,
                    state_root:     0xc1dc3c37edf5ddc216e4dc650dbf27903e4ed69ea72695476e1962e43a8c851d,
                    body_root:      0xd30df4c482d4828b35fd740f65ec1cea1ff83813a2a4312a3c6d97c244751962
                }),
                execution: ExecutionPayloadHeader({
                    parent_hash: 0xcda9605780ee8cfb8c4f56a2254e3c8988ba162cef809592cb0f5a5ec84d873f,
                    fee_recipient: 0xe349aAaFb737c8d1ab6e05c4ecBf0E9Bc62b6495,
                    state_root: 0xe8990a6962cfd916d6525d376573cdf3543cccf46903fdb144437c1fdcfd2706,
                    receipts_root: 0x8e06c9c19e25483f3ddbf7268bceb514b75751270a2e447c2b52ccb7fa7792a3,
                    logs_bloom: 0x045738d5ce2cc26c95dbc66198de172998aae577cf15f0bee00bd2f81dd3399a,
                    prev_randao: 0xf646b2177a805fbd96679623d50d47b04e83a09b3047560cbadb98ada1c9d241,
                    block_number: 17071632,
                    gas_limit: 30000000,
                    gas_used: 13961389,
                    timestamp: 1681797263,
                    extra_data: 0x6d4aaa029bdbb7fc4ab36f19e31cd1e171050aa2dbec039626bbc4c121c0dbc2,
                    base_fee_per_gas: 31074518104,
                    block_hash: 0x15c5541d98d6e8faab6ed96f4c168d8eab59df5245a7d846336fa4816223ba9d,
                    transactions_root: 0xa2f9ea46c6e7a19a506b14a915549ec40cd08ff4dd4ca28710029496e815d3dd,
                    withdrawals_root: 0x85d8aa49100ff09c1b60ae3742915b52ba1d0a38cdcb30fdf11a1ac4fef33fe4
                }),
                execution_branch: execution_branch1
            }),
            signature_sync_committee: sync_committee_case4(),
            finalized_header: LightClientHeader({
                beacon: BeaconBlockHeader({
                    slot:           6247680,
                    proposer_index: 474260,
                    parent_root:    0x32890a5cec061379aee67282af486f6d0be0e1aecd045638b8ba0a27b8aa24a5,
                    state_root:     0x7bfbd4d8c5015b7a5d331a4a7de508765afa740f86f5bd1d68da419999f0e126,
                    body_root:      0x3c2cb11fdaec2d4d3448c90d3cb68bf20c369f17a965885d0c359e2360f94964
                }),
                execution: ExecutionPayloadHeader({
                    parent_hash: 0x16f57832558f6490fcc88588a58c62556707def7a5c8a876a09128a09e9bc099,
                    fee_recipient: 0x758A4A45dd08D826FC3f2436ce3FA263fB1A4F42,
                    state_root: 0xa749ff06dfddd8bcd6507d529cf8c5f4ab7d34f05671c055f25d934714a5b023,
                    receipts_root: 0x5e1dccf2deeb66edfe17452c5efdb2c17420217e34c3acb1de54d7f29ba7dc4e,
                    logs_bloom: 0x8b50dc159b65a441e85099875dbf11271df736b423716e07491062862edf6ec8,
                    prev_randao: 0xf02691e3cfa689b17700639c42a8815c2ebfe095cb7b5be3333951b831a9cb6e,
                    block_number: 17071542,
                    gas_limit: 30000000,
                    gas_used: 11574124,
                    timestamp: 1681796183,
                    extra_data: 0xebd940a554baa1963cd1d00e6f94ccdd85fa52c8092d207b7d566de6a840834d,
                    base_fee_per_gas: 37106869809,
                    block_hash: 0x386c89b6a7c46f5ebcafde98872a3b5556df9864f3f90a2147a44725c227b4af,
                    transactions_root: 0xd1a107a20b808e880d38c8a2fb2e0b4e16786a070f73ae75e5c5a9db361b413a,
                    withdrawals_root: 0x440952937693d3191846650a65d68f001c1e33ab410cf5d7e9b779adfcd30e95
                }),
                execution_branch: execution_branch2
            }),
            finality_branch: finality_branch,
            sync_aggregate: SyncAggregate({
                sync_committee_bits:[
                    bytes32(0xfffffffffffffffffffefffffffffffffffffffffffdffefffffffffffffffff),
                    bytes32(0xffffffbfffffffffffffbffffffffbfffffffffffffffffeffffffffffffffff)
                ],
                sync_committee_signature: hex'a106572a71354b5e3a204fc92bdd530988c7f9354c25daada08b035343eaf93dfb93dadbd2fcacf83b601d5c701af40306644120ef9e776c4ad53e84b27db4e93847631fbb7c8923ad373acb124510c4e902107b827b095eb545c26170645ff5'
            }),
            fork_version: 0x03000000,
            signature_slot: 6247771
        });
    }

    function build_header_update() internal pure returns (FinalizedHeaderUpdate memory) {
        bytes32[] memory finality_branch = new bytes32[](6);
        finality_branch[0] = 0x01fa020000000000000000000000000000000000000000000000000000000000;
        finality_branch[1] = 0x9a9b8ab6ebca0c159b17535ecc0fbbe2a11d1834a4847eae4291ddcac1662c9e;
        finality_branch[2] = 0xd2dfabb68f046bea102015a3566d0191b0c74ddad25f3d26149780bb54f001db;
        finality_branch[3] = 0x1d40972bf50fdf4f4d76be3a032eac950590c093f4c3b6c8def17f691bc8b12e;
        finality_branch[4] = 0xb760b062d233e0e95e572d9e13a53c8df49d04da4314a5cb5c9da4e678f78f41;
        finality_branch[5] = 0xc88b7dbb562a16fecd437d75e34b69a9b38b3e0920eeb8653b156adbd2b5c0a4;

        bytes32[] memory execution_branch1 = new bytes32[](4);
        execution_branch1[0] = 0x8a7358862db6c2fe33992164fec582568355e6b92966d2054fd1be8e07bcf2f3;
        execution_branch1[1] = 0x336488033fe5f3ef4ccc12af07b9370b92e553e35ecb4a337a1b1c0e4afe1e0e;
        execution_branch1[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        execution_branch1[3] = 0x08881a2e40a83114571790d85f6b1a46272e61286245eb33af9efc2812517a70;

        bytes32[] memory execution_branch2 = new bytes32[](4);
        execution_branch2[0] = 0x13f6acacb037274209472712a34f9a1a21017ae5fa703367b0649651b636a9de;
        execution_branch2[1] = 0x336488033fe5f3ef4ccc12af07b9370b92e553e35ecb4a337a1b1c0e4afe1e0e;
        execution_branch2[2] = 0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71;
        execution_branch2[3] = 0xa2126dd89b4bdcad82a613ca38a6a88da5460437381909ffdea2c7c78e63ca41;

        return FinalizedHeaderUpdate({
            attested_header: LightClientHeader({
                beacon: BeaconBlockHeader({
                    slot:           6242416,
                    proposer_index: 229099,
                    parent_root:    0xf5104bfe050388efbecbb2c73a951159772575f856a4d6ee5f50febe0b81dead,
                    state_root:     0x7d6f7006eda426c4a5822ea0eef4610f13e08ec266c2dde1c0a63555858693a6,
                    body_root:      0xee7cc4912b81d17b5e906fd661d6092663e7b7006a923cd50527c0bcc2815d3e
                }),
                execution: ExecutionPayloadHeader({
                   parent_hash: 0xebf921ab846588e4a9e5b3f34456c74bb0765444cec8082e7f59c2352ce66236,
                   fee_recipient: 0x388C818CA8B9251b393131C08a736A67ccB19297,
                   state_root: 0x9afb0674d2f53bc02e797e4d2ee39641086d6c8d4f0318288150bb9d7cb917a1,
                   receipts_root: 0x20087c22c2b43145cd8d46ff918d0c4bbd2b9160602efff012a813829b505b8a,
                   logs_bloom: 0xfae85e9ec52a124e4f635f032d681f1605435c87e7ad4d7c6ca1ffdf3d0e4072,
                   prev_randao: 0xc0e3706af4d84e83ff4d3081c852f9279453026b499b519a0cae1c5f7e60b577,
                   block_number: 17066374,
                   gas_limit: 30000000,
                   gas_used: 10083338,
                   timestamp: 1681733015,
                   extra_data: 0x190fd78b5f762c7f3826645d420b26ce6115958a22d2e5530c5e10629887bcf8,
                   base_fee_per_gas: 26147902783,
                   block_hash: 0x28391774a73b48e2fc48ecbfd62422e308f4c401641480beac0b3ac548cdac85,
                   transactions_root: 0x8f00687a32e53e5e450467999d362833478ce8abcb22464e982062110b67eea8,
                   withdrawals_root: 0x7370d2b4909e806bc7764b9d5744e0fb61e8c492fa22bbd6b9483cbfcd4fc484
                }),
                execution_branch: execution_branch1
            }),
            signature_sync_committee: sync_committee_case4(),
            finalized_header: LightClientHeader({
                beacon: BeaconBlockHeader({
                    slot:           6242336,
                    proposer_index: 560243,
                    parent_root:    0x57eca7179405844ace3c4bf111776baddc1cbbf79230b08928f9a5dd9d2461d5,
                    state_root:     0xd467ed0e15d8418847a2564005b999c0fe2dfa7ca26e60295c06f91a35d7b4db,
                    body_root:      0x45dc7617fa8ebdeb0a6aaa199636ec00b84b4125dbe1363e3c3e0e99f8263189
                }),
                execution: ExecutionPayloadHeader({
                    parent_hash: 0xc8468f21d66fd7db93e4f05febba48feb687ca0743b12a86c5eb4626a73ced21,
                    fee_recipient: 0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5,
                    state_root: 0x936d8f057ea60c9d87e116ed71e9376d0c5f8c4ec9c50b7c2066788b03e41368,
                    receipts_root: 0x8087023bddde58b5d55e8745295eeddd6ee81ecd9ee946e0abe5a24fbf9b8f02,
                    logs_bloom: 0x2169f895491475eabb3cd5e1bb1484a9cd99175de3750ad807fd1c3fbc993e74,
                    prev_randao: 0xcf8b9f6ae3f0948d762235529ebd99bdd3b853eb164c38c1239e3b2f38bc3aa9,
                    block_number: 17066295,
                    gas_limit: 30000000,
                    gas_used: 20574816,
                    timestamp: 1681732055,
                    extra_data: 0xd77cd27fad374ee5b9ad6670e15de0bd12de0512106f7d7071f31aa5fde432ae,
                    base_fee_per_gas: 27562011582,
                    block_hash: 0x5f1940f7c5f726045adff65890e28393a4a08f476d4dae50f74e8bc67de2f68b,
                    transactions_root: 0x8dca4857406b06ae6a0161f4e28854ab9ad570995d0af003917af4e5146d4b2a,
                    withdrawals_root: 0x8cf868192fee7621ad486083a7708e6b99c1d23d36b5eef45ff50ec2ffdbf31b
                }),
                execution_branch: execution_branch2
            }),
            finality_branch: finality_branch,
            sync_aggregate: SyncAggregate({
                sync_committee_bits:[
                    bytes32(0xfffffffffffffffffffffffffffffffffffffffffffdffefffffffffffffffff),
                    bytes32(0xffffffffffffffffffffbffffffffffffffffffffffffffeffffffffffffffff)
                ],
                sync_committee_signature: hex'a120d106dce300af610ce7032a25baf10341daa4dc90cdc3b601996fb2a54ef7e32c35acb27bbfeea1071003cab95cc90f313307a63450b4ca867263da37da8fd46714013b14f8dbd763aee8141278c414d6d3612dda0975a38ccda42326aae4'
            }),
            fork_version: 0x03000000,
            signature_slot: 6242418
        });
    }

    function build_next_sync_committee_branch() internal pure returns (bytes32[] memory) {
        bytes32[] memory next_sync_committee_branch = new bytes32[](5);
        // root next_sync_committee in attested_header
        next_sync_committee_branch[0] = 0x344e99e6b29e1ffa0481053f25004cd8a0e0417804f3a22eaecb9e0d2948fb70;
        next_sync_committee_branch[1] = 0xcd63266caa67a7567f3b078562e45e26e6e4f6bd460497c719606b1810935095;
        next_sync_committee_branch[2] = 0x1d40972bf50fdf4f4d76be3a032eac950590c093f4c3b6c8def17f691bc8b12e;
        next_sync_committee_branch[3] = 0xb760b062d233e0e95e572d9e13a53c8df49d04da4314a5cb5c9da4e678f78f41;
        next_sync_committee_branch[4] = 0xc88b7dbb562a16fecd437d75e34b69a9b38b3e0920eeb8653b156adbd2b5c0a4;
        return next_sync_committee_branch;
    }

    function sum(bytes32[2] memory x) internal pure returns (uint256) {
        return countSetBits(uint(x[0])) + countSetBits(uint(x[1]));
    }

    function test_sum_sync_committee_bits() public {
        bytes32[2] memory sync_committee_bits = [
            bytes32(0xfffffffffffffffffffffffffffffffffffffffffffdffefffffffffffffffff),
            bytes32(0xffffffffffffffffffffbffffffffffffffffffffffffffeffffffffffffffff)
        ];
        assertEq(sum(sync_committee_bits), 508);
    }
}
