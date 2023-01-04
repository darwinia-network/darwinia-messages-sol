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

    function test_count_set_bits_fuzz(uint x) public {
        uint y = countSetBits(x);
        assertEq(y, csb(x));
    }

    function csb(uint x) internal pure returns (uint c) {
        for (c; x > 0; c++)
            x &= x - 1;
    }

    function test_is_set() public {
        uint bitVector = 3;
        assertTrue(isSet(bitVector, 0));
        assertTrue(isSet(bitVector, 1));
        assertTrue(!isSet(bitVector, 2));
        assertTrue(!isSet(bitVector, 255));
    }

    function test_set() public {
        uint bitVector = 0;
        bitVector = set(bitVector, 0);
        assertTrue(isSet(bitVector, 0));
        assertTrue(!isSet(bitVector, 255));
        bitVector = set(bitVector, 255);
        assertTrue(isSet(bitVector, 255));
    }

    function test_clean() public {
        uint bitVector = 3;
        bitVector = clear(bitVector, 0);
        assertTrue(!isSet(bitVector, 0));
        bitVector = clear(bitVector, 1);
        assertTrue(!isSet(bitVector, 1));
        bitVector = clear(bitVector, 2);
        assertTrue(!isSet(bitVector, 2));
        assertTrue(!isSet(bitVector, 255));
    }

    function test_create_bitfield() public {
        uint8[] memory bitsToSet = new uint8[](3);
        bitsToSet[0] = 0;
        bitsToSet[1] = 5;
        bitsToSet[2] = 8;
        uint bitfield = createBitfield(bitsToSet);
        assertEq(bitfield, 289);
    }


    // 0b11110110100101000101100110101011000100000111011100000011010001000100101011111011011101001
    // 0b00010100000100000100000110001010000100000110001100000010000000000100001011001011001101001
    function test_random_n_bits_with_prior_check() public {
        uint seed = 0;
        uint prior = 596192631902738161293719273;
        uint bitfield = randomNBitsWithPriorCheck(seed, prior, 25, 128);
        assertEq(bitfield, 48510566485887452090570345);
    }
}
