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

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../test.sol";
import "../../../utils/bls12381/Fp.sol";

contract FPTest is DSTest {
    using FP for Fp;

    function test_serialize() public {
        Fp memory q = FP.q();
        assertEq0(q.serialize(), hex'1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab');
    }

    function test_is_valid() public {
        Fp memory q = FP.q();
        assertTrue(!q.is_valid());
    }

    function test_is_zero() public {
        Fp memory q = FP.q();
        Fp memory zero = FP.zero();
        assertTrue(zero.is_zero());
        assertTrue(!q.is_zero());
    }
}
