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

import "./Bits.sol";

contract Bitfield {
    using Bits for uint256;

    /// @dev Constants used to efficiently calculate the hamming weight of a bitfield. See
    /// https://en.wikipedia.org/wiki/Hamming_weight#Efficient_implementation for an explanation of those constants.
    uint256 private constant M1 =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 private constant M2 =
        0x3333333333333333333333333333333333333333333333333333333333333333;
    uint256 private constant M4 =
        0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;
    uint256 private constant M8 =
        0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff;
    uint256 private constant M16 =
        0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff;
    uint256 private constant M32 =
        0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff;
    uint256 private constant M64 =
        0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff;
    uint256 private constant M128 =
        0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    uint256[20] private BIG_PRIME = [
        1000003,1000033,1000037,1000039,1000081,1000099,1000117,1000121,1000133,1000151,
        1000159,1000171,1000183,1000187,1000193,1000199,1000211,1000213,1000231,1000249
    ];

    /// @notice Draws a random number, derives an index in the bitfield, and sets the bit if it is in the `prior` and not
    /// yet set. Repeats that `n` times.
    function randomNBitsWithPriorCheck(
        uint256 seed,
        uint256 prior,
        uint256 n,
        uint256 length
    ) internal view returns (uint256 bitfield) {
        require(
            n <= countSetBits(prior),
            "invalid n"
        );
        require(
            length <= 256 && n <= length,
            "invalid length"
        );

        uint256 prime = BIG_PRIME[seed%20];
        uint256 begin = seed % 256;
        uint256 found = 0;

        for (uint256 i = 0; found < n; ++i) {
            uint8 index = uint8((prime * (begin + i)) % length);

            // require randomly seclected bit to be set in prior
            if ((prior >> index) & 1 == 1) {
                bitfield = set(bitfield, index);
                found++;
            }
        }

        return bitfield;
    }

    function createBitfield(uint8[] memory bitsToSet)
        internal
        pure
        returns (uint256 bitfield)
    {
        uint256 length = bitsToSet.length;
        for (uint256 i = 0; i < length; ++i) {
            bitfield = set(bitfield, bitsToSet[i]);
        }

        return bitfield;
    }

    /// @notice Calculates the number of set bits by using the hamming weight of the bitfield.
    /// The alogrithm below is implemented after https://en.wikipedia.org/wiki/Hamming_weight#Efficient_implementation.
    /// Further improvements are possible, see the article above.
    function countSetBits(uint256 x) internal pure returns (uint256) {
        x = (x & M1) + ((x >> 1) & M1); //put count of each  2 bits into those  2 bits
        x = (x & M2) + ((x >> 2) & M2); //put count of each  4 bits into those  4 bits
        x = (x & M4) + ((x >> 4) & M4); //put count of each  8 bits into those  8 bits
        x = (x & M8) + ((x >> 8) & M8); //put count of each 16 bits into those 16 bits
        x = (x & M16) + ((x >> 16) & M16); //put count of each 32 bits into those 32 bits
        x = (x & M32) + ((x >> 32) & M32); //put count of each 64 bits into those 64 bits
        x = (x & M64) + ((x >> 64) & M64); //put count of each 128 bits into those 128 bits
        x = (x & M128) + ((x >> 128) & M128); //put count of each 256 bits into those 256 bits
        return x;
    }

    function isSet(uint256 self, uint8 index)
        internal
        pure
        returns (bool)
    {
        return self.bit(index) == 1;
    }

    function set(uint256 self, uint8 index) internal pure returns (uint256) {
        return self.setBit(index);
    }

    function clear(uint256 self, uint8 index) internal pure returns (uint256) {
        return self.clearBit(index);
    }
}
