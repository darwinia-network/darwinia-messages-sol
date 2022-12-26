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

library Nibble {
    /// @notice Converts a byte array into a nibble array by splitting each byte into two nibbles.
    ///         Resulting nibble array will be exactly twice as long as the input byte array.
    //
    /// @param _bytes Input byte array to convert.
    //
    /// @return Resulting nibble array.
    function toNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        uint256 bytesLength = _bytes.length;
        bytes memory nibbles = new bytes(bytesLength * 2);
        bytes1 b;

        for (uint256 i = 0; i < bytesLength; ) {
            b = _bytes[i];
            nibbles[i * 2] = b >> 4;
            nibbles[i * 2 + 1] = b & 0x0f;
            unchecked {
                ++i;
            }
        }

        return nibbles;
    }

}
