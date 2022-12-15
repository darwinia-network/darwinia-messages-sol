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

import "../../utils/Math.sol";

contract MathTest is Math {
    function property_get_power_of_two_ceil(uint x) public pure {
        if (x == 0 || x == type(uint).max) return;
        uint y = get_power_of_two_ceil(x);
        assert(y / 2 < x && x <= y);
    }

    function property_log_2(uint x) public pure {
        if (x <= 1) return;
        uint y = log_2(x);
        assert(2**(y-1) < x && x <= 2**y);
    }

    function property_max(uint x, uint y) public pure {
        uint z = _max(x, y);
        if (z == x) {
            assert(z >= y);
        } {
            assert(z >= x);
        }
    }
}
