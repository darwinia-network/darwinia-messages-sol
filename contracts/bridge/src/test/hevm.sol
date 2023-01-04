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

interface Hevm {
    function roll(uint) external;
    function warp(uint) external;
    function addr(uint256) external returns (address);
    function sign(uint256,bytes32) external returns (uint8,bytes32,bytes32);
    function load(address c, bytes32 loc) external returns (bytes32 val);
    function ffi(string[] calldata) external returns (bytes memory);
}

