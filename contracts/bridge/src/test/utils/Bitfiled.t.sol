// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../lib/ds-test/src/test.sol";
import "../../utils/Bitfield.sol";

contract BitfiledTest is Bitfield, DSTest {
    function test_count_set_bits() public {
        uint bitVector = 1;
        assertEq(countSetBits(bitVector), 1);
        bitVector = 2;
        assertEq(countSetBits(bitVector), 1);
        bitVector = 3;
        assertEq(countSetBits(bitVector), 2);
    }

    // function test_is_set() public {
    //     uint[] memory bitVector = new uint[](3);
    //     bitVector[0] = 1;
    //     bitVector[1] = 2;
    //     bitVector[2] = 3;
    //     assertTrue(isSet(bitVector, 0));
    //     assertTrue(!isSet(bitVector, 1));
    //     assertTrue(!isSet(bitVector, 256));
    //     assertTrue(isSet(bitVector, 257));
    //     assertTrue(isSet(bitVector, 512));
    //     assertTrue(isSet(bitVector, 513));
    //     assertTrue(!isSet(bitVector, 514));
    // }

    // function test_set() public {
    //     uint[] memory bitVector = new uint[](3);
    //     bitVector[0] = 1;
    //     bitVector[1] = 2;
    //     bitVector[2] = 3;
    //     set(bitVector, 1);
    //     assertTrue(isSet(bitVector, 1));
    //     set(bitVector, 256);
    //     assertTrue(isSet(bitVector, 256));
    //     set(bitVector, 514);
    //     assertTrue(isSet(bitVector, 514));
    // }

    // function test_clean() public {
    //     uint[] memory bitVector = new uint[](3);
    //     bitVector[0] = 1;
    //     bitVector[1] = 2;
    //     bitVector[2] = 3;
    //     clear(bitVector, 0);
    //     assertTrue(!isSet(bitVector, 0));
    //     clear(bitVector, 257);
    //     assertTrue(!isSet(bitVector, 257));
    //     clear(bitVector, 512);
    //     assertTrue(!isSet(bitVector, 512));
    //     clear(bitVector, 513);
    //     assertTrue(!isSet(bitVector, 513));
    // }

    // function test_create_bitfield() public {
    //     uint[] memory bitsToSet = new uint[](3);
    //     bitsToSet[0] = 0;
    //     bitsToSet[1] = 5;
    //     bitsToSet[2] = 8;
    //     uint[] memory bitfield = createBitfield(bitsToSet, 9);
    //     assertEq(bitfield.length, 1);
    //     assertEq(bitfield[0], 289);
    // }


    // 0b11110110100101000101100110101011000100000111011100000011010001000100101011111011011101001
    // 0b01010010100101000000100100001010000100000010001100000010000001000000101001011010001101000
    function test_random_n_bits_with_prior_check() public {
        uint seed = 0;
        uint prior = 596192631902738161293719273;
        uint bitfield = randomNBitsWithPriorCheck(seed, prior, 25, 128);
        assertEq(bitfield, 53346269764345968789395048);
    }
}
