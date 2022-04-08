// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../../../lib/ds-test/src/test.sol";
import "../../utils/Bits.sol";

contract BitsTest is DSTest {
    using Bits for uint;

    uint internal constant ZERO = uint(0);
    uint internal constant ONE = uint(1);
    uint internal constant ONES = type(uint256).max;

    // function test_bit_and() public {
    //     for (uint8 i = 0; i < 12; i++) {
    //         assertEq(ONES.bitAnd(ONES, i*20), 1);
    //         assertEq(ONES.bitAnd(ZERO, i*20), 0);
    //         assertEq(ZERO.bitAnd(ONES, i*20), 0);
    //         assertEq(ZERO.bitAnd(ZERO, i*20), 0);
    //     }
    // }

    // function test_bit_equal() public {
    //     for (uint8 i = 0; i < 12; i++) {
    //         assertTrue(ONES.bitEqual(ONES, i*20));
    //         assertTrue(!ONES.bitEqual(ZERO, i*20));
    //     }
    // }

    // function test_bit_or() public {
    //     for (uint8 i = 0; i < 12; i++) {
    //         assertEq(ONES.bitOr(ONES, i*20), 1);
    //         assertEq(ONES.bitOr(ZERO, i*20), 1);
    //         assertEq(ZERO.bitOr(ONES, i*20), 1);
    //         assertEq(ZERO.bitOr(ZERO, i*20), 0);
    //     }
    // }

    // function test_bit_set() public {
    //     for (uint8 i = 0; i < 12; i++) {
    //         assertTrue(ONES.bitSet(i*20));
    //     }
    // }

    // function test_bits_bits_with_different_indices() public {
    //     for (uint8 i = 0; i < 12; i++) {
    //         assertEq(ONES.bits(i*20, 5), 31);
    //     }
    // }

    // function test_bits_bits_with_different_num_bits() public {
    //     for (uint8 i = 1; i < 12; i++) {
    //         assertEq(ONES.bits(0, i), ONES >> (256 - i));
    //     }
    // }

    // function test_bits_get_all() public {
    //     assertEq(ONES.bits(0, 256), ONES);
    // }

    // function test_get_upper_half() public {
    //     assertEq(ONES.bits(128, 128), ONES >> 128);
    // }

    // function test_bits_get_lower_half() public {
    //     assertEq(ONES.bits(0, 128), ONES >> 128);
    // }

    // function testFail_bits_throws_num_bits_zero() public pure {
    //     ONES.bits(0, 0);
    // }

    // function testFail_bits_bits_throws_index_and_length_oob() public pure {
    //     ONES.bits(5, 252);
    // }

    // function test_bits_bit_xor() public {
    //     for (uint8 i = 0; i < 12; i++) {
    //         assertEq(ONES.bitXor(ONES, i*20), 0);
    //         assertEq(ONES.bitXor(ZERO, i*20), 1);
    //         assertEq(ZERO.bitXor(ONES, i*20), 1);
    //         assertEq(ZERO.bitXor(ZERO, i*20), 0);
    //     }
    // }

    // function test_bits_clear_bit() public {
    //     for (uint8 i = 0; i < 12; i++) {
    //         assertEq(ONES.clearBit(i*20).bit(i*20), 0);
    //     }
    // }

    // function test_bits_bit() public {
    //     for (uint8 i = 0; i < 12; i++) {
    //         uint v = (ONE << i*20) * (i % 2);
    //         assertEq(v.bit(i*20), i % 2);
    //     }
    // }

    // function test_bits_bit_not() public {
    //     for (uint8 i = 0; i < 12; i++) {
    //         uint v = (ONE << i*20) * (i % 2);
    //         assertEq(v.bitNot(i*20), 1 - i % 2);
    //     }
    // }

    // function test_bits_highest_bit_set_all_lower_set() public {
    //     for (uint8 i = 0; i < 12; i += 20) {
    //         assertEq((ONES >> i).highestBitSet(), (255 - i));
    //     }
    // }

    // function test_bits_highest_bit_set_single_bit() public {
    //     for (uint8 i = 0; i < 12; i += 20) {
    //         assertEq((ONE << i).highestBitSet(), i);
    //     }
    // }

    // function testFail_bits_highest_bit_set_throws_bit_field_is_zero() public pure {
    //     ZERO.highestBitSet();
    // }

    // function test_bits_lowest_bit_set_all_higher_set() public {
    //     for (uint8 i = 0; i < 12; i += 20) {
    //         assertEq((ONES << i).lowestBitSet(), i);
    //     }
    // }

    // function test_bits_lowest_bit_set_single_bit() public {
    //     for (uint8 i = 0; i < 12; i += 20) {
    //         assertEq((ONE << i).lowestBitSet(), i);
    //     }
    // }

    // function testFail_bits_lowest_bit_set_throws_bit_field_is_zero() public pure {
    //     ZERO.lowestBitSet();
    // }

    // function test_bits_set_bit() public {
    //     for (uint8 i = 0; i < 12; i++) {
    //         assertEq(ZERO.setBit(i*20), ONE << i*20);
    //     }
    // }

    // function test_bits_toggle_bit() public {
    //     for (uint8 i = 0; i < 12; i++) {
    //         uint v = ZERO.toggleBit(i*20);
    //         assertEq(v, ONE << i*20);
    //         assertEq(v.toggleBit(i*20), 0);
    //     }
    // }
}
