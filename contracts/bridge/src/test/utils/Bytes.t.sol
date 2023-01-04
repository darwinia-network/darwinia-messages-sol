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
import "../../utils/Bytes.sol";

contract BytesTest is DSTest {
    /// @dev Tests that the `slice` function works as expected when starting from
    /// index 0.
    function test_slice_fromZeroIdx_works() public {
        bytes memory input = hex"11223344556677889900";

        // Exhaustively check if all possible slices starting from index 0 are correct.
        assertEq0(Bytes.slice(input, 0, 0), hex"");
        assertEq0(Bytes.slice(input, 0, 1), hex"11");
        assertEq0(Bytes.slice(input, 0, 2), hex"1122");
        assertEq0(Bytes.slice(input, 0, 3), hex"112233");
        assertEq0(Bytes.slice(input, 0, 4), hex"11223344");
        assertEq0(Bytes.slice(input, 0, 5), hex"1122334455");
        assertEq0(Bytes.slice(input, 0, 6), hex"112233445566");
        assertEq0(Bytes.slice(input, 0, 7), hex"11223344556677");
        assertEq0(Bytes.slice(input, 0, 8), hex"1122334455667788");
        assertEq0(Bytes.slice(input, 0, 9), hex"112233445566778899");
        assertEq0(Bytes.slice(input, 0, 10), hex"11223344556677889900");
    }

    /// @dev Tests that the `slice` function works as expected when starting from
    /// indexes [1, 9] with lengths [1, 9], in reverse order.
    function test_slice_fromNonZeroIdx_works() public {
        bytes memory input = hex"11223344556677889900";

        // Exhaustively check correctness of slices starting from indexes [1, 9]
        // and spanning [1, 9] bytes, in reverse order
        assertEq0(Bytes.slice(input, 9, 1), hex"00");
        assertEq0(Bytes.slice(input, 8, 2), hex"9900");
        assertEq0(Bytes.slice(input, 7, 3), hex"889900");
        assertEq0(Bytes.slice(input, 6, 4), hex"77889900");
        assertEq0(Bytes.slice(input, 5, 5), hex"6677889900");
        assertEq0(Bytes.slice(input, 4, 6), hex"556677889900");
        assertEq0(Bytes.slice(input, 3, 7), hex"44556677889900");
        assertEq0(Bytes.slice(input, 2, 8), hex"3344556677889900");
        assertEq0(Bytes.slice(input, 1, 9), hex"223344556677889900");
    }

    /// @dev Tests that the `slice` function works as expected when slicing between
    /// multiple words in memory. In this case, we test that a 2 byte slice between
    /// the 32nd byte of the first word and the 1st byte of the second word is
    /// correct.
    function test_slice_acrossWords_works() public {
        bytes
            memory input = hex"00000000000000000000000000000000000000000000000000000000000000112200000000000000000000000000000000000000000000000000000000000000";

        assertEq0(Bytes.slice(input, 31, 2), hex"1122");
    }

    /// @dev Tests that the `slice` function works as expected when slicing between
    /// multiple words in memory. In this case, we test that a 34 byte slice between
    /// 3 separate words returns the correct result.
    function test_slice_acrossMultipleWords_works() public {
        bytes
            memory input = hex"000000000000000000000000000000000000000000000000000000000000001122FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF1100000000000000000000000000000000000000000000000000000000000000";
        bytes
            memory expected = hex"1122FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF11";

        assertEq0(Bytes.slice(input, 31, 34), expected);
    }

    /// @dev Test that the `equal` function in the `Bytes` library returns `false` if given
    /// two non-equal byte arrays.
    function testFuzz_equal_notEqual_works(bytes memory _a, bytes memory _b) public {
        if (!manualEq(_a, _b)) {
            assertTrue(!Bytes.equals(_a, _b));
        }
    }

    /// @dev Test whether or not the `equal` function in the `Bytes` library is equivalent
    /// to manually checking equality of the two dynamic `bytes` arrays in memory.
    function testDiff_equal_works(bytes memory _a, bytes memory _b) public {
        assertTrue(Bytes.equals(_a, _b) == manualEq(_a, _b));
    }

    /// @dev Tests that, when given an input bytes array of length `n`,
    /// the `slice` function will always revert if `_start + _length > n`.
    function testFailFuzz_slice_outOfBounds_reverts(
        bytes memory _input,
        uint256 _start,
        uint256 _length
    ) public {
        // We want a valid start index and a length that will not overflow.
        if (_start < _input.length && _length < type(uint256).max - 31) {
            // But, we want an invalid slice length.
            if (_start + _length > _input.length) {
                // vm.expectRevert("slice_outOfBounds");
                Bytes.slice(_input, _start, _length);
            }
            fail();
        }
        fail();
    }

    /// @dev Tests that, when given a length `n` that is greater than `type(uint256).max - 31`,
    /// the `slice` function reverts.
    function testFailFuzz_slice_lengthOverflows_reverts(
        bytes memory _input,
        uint256 _start,
        uint256 _length
    ) public {
        // Ensure that the `_length` will overflow if a number >= 31 is added to it.
        if (_length > type(uint256).max - 31) {
            // vm.expectRevert("slice_overflow");
            Bytes.slice(_input, _start, _length);
        }
        fail();
    }

    /// @dev Tests that, when given a length `n` that is greater than `type(uint256).max - 31`,
    /// the `slice` function reverts.
    function testFailFuzz_slice_rangeOverflows_reverts(
        bytes memory _input,
        uint256 _start,
        uint256 _length
    ) public {
        // Ensure that `_length` is a realistic length of a slice. This is to make sure
        // we revert on the correct require statement.
        if (_length < _input.length) {
            // Ensure that `_start` will overflow if `_length` is added to it.
            if (_start > type(uint256).max - _length) {
                // vm.expectRevert("slice_overflow");
                Bytes.slice(_input, _start, _length);
            }
            fail();
        }
        fail();
    }

    ////////////////////////////////////////////////////////////////
    //                          HELPERS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev Utility function to manually check equality of two dynamic `bytes` arrays in memory.
    function manualEq(bytes memory _a, bytes memory _b) internal pure returns (bool) {
        bool _eq;
        assembly {
            _eq := and(
                // Check if the contents of the two bytes arrays are equal in memory.
                eq(keccak256(add(0x20, _a), mload(_a)), keccak256(add(0x20, _b), mload(_b))),
                // Check if the length of the two bytes arrays are equal in memory.
                // This is redundant given the above check, but included for completeness.
                eq(mload(_a), mload(_b))
            )
        }
        return _eq;
    }

}
