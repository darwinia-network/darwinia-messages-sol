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
import "../../../utils/trie/Nibble.sol";

contract NibbleTest is DSTest {

    /// @dev Tests that, given an input of 5 bytes, the `toNibbles` function returns
    /// an array of 10 nibbles corresponding to the input data.
    function test_toNibbles_expectedResult5Bytes_works() public {
        bytes memory input = hex"1234567890";
        bytes memory expected = hex"01020304050607080900";
        bytes memory actual = Nibble.toNibbles(input);

        assertEq(input.length * 2, actual.length);
        assertEq(expected.length, actual.length);
        assertEq0(actual, expected);
    }

    /// @dev Tests that, given an input of 128 bytes, the `toNibbles` function returns
    /// an array of 256 nibbles corresponding to the input data.
    /// This test exists to ensure that, given a large input, the `toNibbles` function
    /// works as expected.
    function test_toNibbles_expectedResult128Bytes_works() public {
        bytes memory input = hex"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f";
        bytes memory expected = hex"0000000100020003000400050006000700080009000a000b000c000d000e000f0100010101020103010401050106010701080109010a010b010c010d010e010f0200020102020203020402050206020702080209020a020b020c020d020e020f0300030103020303030403050306030703080309030a030b030c030d030e030f0400040104020403040404050406040704080409040a040b040c040d040e040f0500050105020503050405050506050705080509050a050b050c050d050e050f0600060106020603060406050606060706080609060a060b060c060d060e060f0700070107020703070407050706070707080709070a070b070c070d070e070f";
        bytes memory actual = Nibble.toNibbles(input);

        assertEq(input.length * 2, actual.length);
        assertEq(expected.length, actual.length);
        assertEq0(actual, expected);
    }

    /// @dev Tests that, given an input of 0 bytes, the `toNibbles` function returns
    /// a zero length array.
    function test_toNibbles_zeroLengthInput_works() public {
        bytes memory input = hex"";
        bytes memory expected = hex"";
        bytes memory actual = Nibble.toNibbles(input);

        assertEq(input.length, 0);
        assertEq(expected.length, 0);
        assertEq(actual.length, 0);
        assertEq0(actual, expected);
    }

    /// @dev Test that the `toNibbles` function in the `Bytes` library is equivalent to the
    /// Yul implementation.
    function testDiff_toNibbles_succeeds(bytes memory _input) public {
        assertEq0(Nibble.toNibbles(_input), toNibblesYul(_input));
    }

    ////////////////////////////////////////////////////////////////
    //                          HELPERS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev Utility function to diff test Solidity version of `toNibbles`
    function toNibblesYul(bytes memory _bytes) internal pure returns (bytes memory) {
        // Allocate memory for the `nibbles` array.
        bytes memory nibbles = new bytes(_bytes.length << 1);

        assembly {
            // Load the length of the passed bytes array from memory
            let bytesLength := mload(_bytes)

            // Store the memory offset of the _bytes array's contents on the stack
            let bytesStart := add(_bytes, 0x20)

            // Store the memory offset of the nibbles array's contents on the stack
            let nibblesStart := add(nibbles, 0x20)

            // Loop through each byte in the input array
            for {
                let i := 0x00
            } lt(i, bytesLength) {
                i := add(i, 0x01)
            } {
                // Get the starting offset of the next 2 bytes in the nibbles array
                let offset := add(nibblesStart, shl(0x01, i))

                // Load the byte at the current index within the `_bytes` array
                let b := byte(0x00, mload(add(bytesStart, i)))

                // Pull out the first nibble and store it in the new array
                mstore8(offset, shr(0x04, b))
                // Pull out the second nibble and store it in the new array
                mstore8(add(offset, 0x01), and(b, 0x0F))
            }
        }

        return nibbles;
    }
}
