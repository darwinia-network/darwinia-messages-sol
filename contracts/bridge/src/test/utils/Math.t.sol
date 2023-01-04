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
import "../../utils/Math.sol";

contract MathTest is DSTest, Math {
    function test_get_power_of_two_ceil() public {
        assertEq(get_power_of_two_ceil(0), 1);
        assertEq(get_power_of_two_ceil(1), 1);
        assertEq(get_power_of_two_ceil(2), 2);
        assertEq(get_power_of_two_ceil(3), 4);
        assertEq(get_power_of_two_ceil(4), 4);
        assertEq(get_power_of_two_ceil(5), 8);
        assertEq(get_power_of_two_ceil(6), 8);
        assertEq(get_power_of_two_ceil(7), 8);
        assertEq(get_power_of_two_ceil(8), 8);
        assertEq(get_power_of_two_ceil(9), 16);
        assertEq(get_power_of_two_ceil(100), 128);
    }

    function test_get_power_of_two_ceil_fuzz(uint x) public {
        if (x < 1 || x >= 0x8000000000000000000000000000000000000000000000000000000000000000) return;
        uint y = log_2(x);
        assertEq(y, _ceilLog2(x));
    }

    function test_log_2() public {
        assertEq(log_2(1), 0);
        assertEq(log_2(2), 1);
        assertEq(log_2(3), 2);
        assertEq(log_2(4), 2);
        assertEq(log_2(5), 3);
        assertEq(log_2(6), 3);
        assertEq(log_2(7), 3);
        assertEq(log_2(8), 3);
        assertEq(log_2(9), 4);
        assertEq(log_2(10), 4);
        assertEq(log_2(11), 4);
        assertEq(log_2(12), 4);
        assertEq(log_2(13), 4);
        assertEq(log_2(14), 4);
        assertEq(log_2(15), 4);
        assertEq(log_2(16), 4);
        assertEq(log_2(17), 5);
        assertEq(log_2(32), 5);
        assertEq(log_2(64), 6);
        assertEq(log_2(128), 7);
        assertEq(log_2(256), 8);
        assertEq(log_2(512), 9);
        assertEq(log_2(1024), 10);
        assertEq(log_2(0xffffffffffffffffffffffffffffffff), 128);
        assertEq(log_2(0x8000000000000000000000000000000000000000000000000000000000000000), 255);
    }

    function prove_get_power_of_two_ceil(uint x) public {
        if (x == 0 || x == type(uint).max) return;
        uint y = get_power_of_two_ceil(x);
        assertTrue(y / 2 < x && x <= y);
    }

    function prove_log_2(uint x) public {
        if (x < 2 || x >= 0x8000000000000000000000000000000000000000000000000000000000000000) return;
        uint y = log_2(x);
        assertTrue(2**(y-1) < x && x <= 2**y);
    }

    function _ceilLog2(uint256 _in) internal pure returns (uint256) {
        require(_in > 0, "Cannot compute ceil(log_2) of 0.");

        if (_in == 1) {
            return 0;
        }

        uint256 val = _in;
        uint256 highest = 0;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & (((uint256(1) << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }

        if ((uint256(1) << highest) != _in) {
            highest += 1;
        }

        return highest;
    }
}
