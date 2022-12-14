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

import "../test.sol";

contract HashTest is DSTest {

    function test_keccak_256() public {
        bytes32 domain = hex'07000000e7acb21061790987fa1c1e745cccfb358370b33e8af2b2c18938e6c2';
        bytes32 header = hex'b82ffe1e2e7d9dd678aaedd630e75192f1e8b802b9a3b61e6cc7fbaf8ecdd6ec';
        uint b = gasleft();
        keccak256(abi.encodePacked(domain,header));
        uint g = b - gasleft();
        emit log_uint(g);
    }

    function test_sha_256() public {
        bytes32 domain = hex'07000000e7acb21061790987fa1c1e745cccfb358370b33e8af2b2c18938e6c2';
        bytes32 header = hex'b82ffe1e2e7d9dd678aaedd630e75192f1e8b802b9a3b61e6cc7fbaf8ecdd6ec';
        uint b = gasleft();
        sha256(abi.encodePacked(domain,header));
        uint g = b - gasleft();
        emit log_uint(g);
    }
}
