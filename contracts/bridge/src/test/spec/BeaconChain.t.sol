// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../test.sol";
import "../../spec/BeaconChain.sol";

contract BeaconChainTest is DSTest, BeaconChain {
    function test_to_little_endian_64() public {
        assertEq(to_little_endian_64(5), hex"0500000000000000");
    }

    function test_beacon_block_header() public {
        // BeaconBlockHeader memory case0 = BeaconBlockHeader({
        //     slot:            13763605646674810374,
        //     proposer_index:  7704591909929553516,
        //     parent_root:     0x98f5655842c7d96474354de483dde443a6eb3180f102c425aae3b6a924332de1,
        //     state_root:      0x38cee1c1ff58231fe19959d16cb805af25618ca1175c39885a8a9a0f6f6560ea,
        //     body_root:       0x36122528bead53899c96cdcc4681c202802edd33a9f7c877c035f566e1fef59e
        // });
        // assertEq(hash_tree_root(case0), 0xff8adc3be9b3361ce323cfa4feee71fcb43e2f8d7156fe08a0e2ec0e1f647069);

        BeaconBlockHeader memory case0 = BeaconBlockHeader({
            slot:            0,
            proposer_index:  5,
            parent_root:     0x7017c98c5b847913fc67c592c9a1effeab447b5278a195e47b5a007e0506aa42,
            state_root:      0x41c65c87848866aaba698de42884841a7749567c267c047593a4e75c15567382,
            body_root:       0x051d6fe7cb277dbfe293310f8ef97da5ddd02580b9a0b436529ec2bfd9ce1034
        });
        assertEq(hash_tree_root(case0), 0x0ff0bc80afdd2749d9dd6ef835826f27f1ffd66068fedcc935bf3c8eca402078);
    }
}
