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

import "../test.sol";
import "./SyncCommittee.t.sol";

contract BeaconChainTest is DSTest, SyncCommitteePreset {
    bytes4 constant private DOMAIN_SYNC_COMMITTEE = 0x07000000;

    function test_to_little_endian_64() public {
        assertEq(to_little_endian_64(5), hex"0500000000000000");
    }

    function test_default_hash() public {
        BeaconBlockHeader memory header;
        assertEq(hash_tree_root(header), 0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c);
    }

    function test_beacon_block_header_hash() public {
        BeaconBlockHeader memory header = BeaconBlockHeader({
            slot:            0,
            proposer_index:  5,
            parent_root:     0x7017c98c5b847913fc67c592c9a1effeab447b5278a195e47b5a007e0506aa42,
            state_root:      0x41c65c87848866aaba698de42884841a7749567c267c047593a4e75c15567382,
            body_root:       0x051d6fe7cb277dbfe293310f8ef97da5ddd02580b9a0b436529ec2bfd9ce1034
        });
        assertEq(hash_tree_root(header), 0x0ff0bc80afdd2749d9dd6ef835826f27f1ffd66068fedcc935bf3c8eca402078);

        BeaconBlockHeader memory case0 = BeaconBlockHeader({
            slot:            13763605646674810374,
            proposer_index:  7704591909929553516,
            parent_root:     0x98f5655842c7d96474354de483dde443a6eb3180f102c425aae3b6a924332de1,
            state_root:      0x38cee1c1ff58231fe19959d16cb805af25618ca1175c39885a8a9a0f6f6560ea,
            body_root:       0x36122528bead53899c96cdcc4681c202802edd33a9f7c877c035f566e1fef59e
        });
        assertEq(hash_tree_root(case0), 0xff8adc3be9b3361ce323cfa4feee71fcb43e2f8d7156fe08a0e2ec0e1f647069);

        BeaconBlockHeader memory case1 = BeaconBlockHeader({
            slot:            10019299140082784664,
            proposer_index:  18123989331871495942,
            parent_root:     0x23d49aa8a8b1f4a235aa0dd0feb61b756e34146f214c23e7bc1be216ae4c253d,
            state_root:      0x414b57928cc173041425ab4be593debe448cd8289b46758912be58c50e0c67ee,
            body_root:       0x74d9e2fb74bdb9dddd4b7a8c59a9a034ad633065708f5816be351c3a21b56d26
        });
        assertEq(hash_tree_root(case1), 0x545efc2b28498b1af4d1a6d99d428d9b5390016c747288e212a8afc183cd3b6e);

        BeaconBlockHeader memory case2 = BeaconBlockHeader({
            slot:            18320068194381506775,
            proposer_index:  16943719066737937667,
            parent_root:     0x139a08968876774d5f5028f409f43132195744f7979bb359072a5294f09e3932,
            state_root:      0x9c81ecf00b648d082f5c9352285f8b62fe9f1dccd1568d585409072f5f5320c9,
            body_root:       0x33591262c3f0b051d527e829a6078f18355b5681432ce96b6a19fd77100368ad
        });
        assertEq(hash_tree_root(case2), 0x226ade03749725dd996c3d229d575c22a1d0f35d6575258a6774de92bbe27879);

        BeaconBlockHeader memory case3 = BeaconBlockHeader({
            slot:            10213987412957032947,
            proposer_index:  13177902785608533696,
            parent_root:     0x2a168723a94641cf51e2ccc4f34fc1453367878c7f0e80250e6125fb5da0b91d,
            state_root:      0xf155c8524f8d3027986900c3378182772cff75688500c64a99555e4354210d91,
            body_root:       0x3befd24dc5b110962f7564059626847985096c99474347cac3b6fa63855f0346
        });
        assertEq(hash_tree_root(case3), 0x31f7efe81a219cf6a926ad08a33130bb683a4b12c0efa700f1a94b7cff56c5ca);

        BeaconBlockHeader memory case4 = BeaconBlockHeader({
            slot:            1607693547755343516,
            proposer_index:  2948892966429505865,
            parent_root:     0x3c82997949fe080fc76a8485ec0d808a75298cac5c7c4841782f231783ac82c1,
            state_root:      0x2ce589b0d77dd2bfdaddc90d754e90605f4831e5d1f92ee7011a08bb058302bd,
            body_root:       0x7ffedf1247087b395827a54e1c6423b0119769cbab99ddc964eef3ce9a285c20
        });
        assertEq(hash_tree_root(case4), 0x2b79dbbd870abbe1066764b2e78bfb9f9e290b196d378fe8ee9442400076df60);
    }

    function test_sync_committee_hash() public {
        SyncCommittee memory case0 = sync_committee_case0();
        assertEq(hash_tree_root(case0), 0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7);

        SyncCommittee memory case1 = sync_committee_case1();
        assertEq(hash_tree_root(case1), 0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7);

        SyncCommittee memory case4 = sync_committee_case4();
        assertEq(hash_tree_root(case4), 0x344e99e6b29e1ffa0481053f25004cd8a0e0417804f3a22eaecb9e0d2948fb70);
    }


    function test_signing_data_hash() public {
        SigningData memory case0 = SigningData({
            object_root: 0x77d2177bb36a540745b23fb49a2193c5df0b21c2f857a065ba1cfe272670b87c,
            domain: 0x49d234a25fd3855f9d0f6a0e072214ff5aa5109247451988ac6a14081020f22a
        });
        assertEq(hash_tree_root(case0), 0xde20872842d90c383a01e6b680e017a5d91b713d21b0aa50e3a49df07aeae932);
    }

    function test_fork_data_hash() public {
        ForkData memory case0 = ForkData({
            current_version: hex'08653791',
            genesis_validators_root: hex'0b09cbef0906dd76ecde1aee95118a7a5138612503fd71405bef3ad92ff96bf7'
        });
        assertEq(hash_tree_root(case0), 0x9e6e0e0f2f91e820ac314cf7c39cc5bfcf950d518cf2343e5e67404be3a1d724);
    }

    function test_compute_signing_root() public {
        BeaconBlockHeader memory header = BeaconBlockHeader({
              slot:            594977,
              proposer_index:  75461,
              parent_root:     0x728e25e46c1a25871bf7fd2f166f9df498258a9a53b00da023bebe1af95802ca,
              state_root:      0xfc0692a950c8eb6f0c1e979151ce07a4f01c13187bbf937406bfa2e71e3e4eb1,
              body_root:       0x297f7ba3dad4b07d238ffab5af582c24c3441598f4901600926db5ed8a6a41ca
        });
        bytes4 fork_version = hex'70000071';
        bytes32 genesis_validators_root = hex'99b09fcd43e5905236c370f184056bec6e6638cfc31a323b304fc4aa789cb4ad';
        bytes32 domain = compute_domain(DOMAIN_SYNC_COMMITTEE, fork_version, genesis_validators_root);
        assertEq(domain, hex'07000000e7acb21061790987fa1c1e745cccfb358370b33e8af2b2c18938e6c2');
        assertEq(compute_signing_root(header, domain), hex'10463446888d7025d20898341d1aaf5a0937041013986c5478d5ab3ecd5fe5d7');
    }

    function test_compute_signing_root2() public {
        bytes32 domain = hex'07000000e7acb21061790987fa1c1e745cccfb358370b33e8af2b2c18938e6c2';
        bytes32 header = hex'b82ffe1e2e7d9dd678aaedd630e75192f1e8b802b9a3b61e6cc7fbaf8ecdd6ec';
        assertEq(hash_node(header, domain), hex'0e8af0f2acda0f48227ed7a28b824716bc87dc6e25916bde8f3efd9459507068');
    }

    function test_is_valid_merkle_branch_case0() public {
        bytes32[] memory branch = new bytes32[](5);
        branch[0] = 0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7;
        branch[1] = 0xc15a3515c2f69c510d27dc829bb763a071d12ed28861665a15eac18be09ec396;
        branch[2] = 0xfeb3abafe78c2a78ed08962a29cb063c00ba6b3ae84ea7ec84bd8700182197dd;
        branch[3] = 0xd2dc4ba9fd4edff6716984136831e70a6b2e74fca27b8097a820cbbaa5a6e3c3;
        branch[4] = 0x988f0289fc602a4a1fb46f95edffddd456a27225f46428e279f97dd827589464;
        assertTrue(
            is_valid_merkle_branch(
                0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7,
                branch,
                5,
                23,
                0xb2e9a7b6f6b11f62b9cfdd07d29c854606460fc8b9925e8ef46a9bbbe33e71e8
            )
        );
    }

    function test_is_valid_merkle_branch_case1() public {
        bytes32[] memory branch = new bytes32[](5);
        branch[0] = 0x5cf5804f5a8dc680445f5efd4069859f3c65dd2db869f1d091f454008f6d7ab7;
        branch[1] = 0x4106a9dd5507877b9f091ff28efe02f5cb8a0fff67911b8a43f88962859ffe0e;
        branch[2] = 0xfeb3abafe78c2a78ed08962a29cb063c00ba6b3ae84ea7ec84bd8700182197dd;
        branch[3] = 0x601f645828951f190c119152e27b6314b5c4b3d2da0c5d2d0f6cbce679f5bb68;
        branch[4] = 0x64232044a15df7c9c6d8c4b3be7606fa32c55a1dd79bf20aaf1ac3e5a6cb8a82;
        assertTrue(
            is_valid_merkle_branch(
                0x86cb4c24efc89ccad5b019bd90cf46891eba6edcaafb374e4cd27ecca324cc4a,
                branch,
                5,
                23,
                0xe71648cecf3a7ac5b399927ec94501d4b8095004a45420c7faae9af314ac8400
            )
        );
    }
}
