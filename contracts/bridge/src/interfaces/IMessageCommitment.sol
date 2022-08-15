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

interface IMessageCommitment {
    function thisChainPosition() external view returns (uint32);
    function thisLanePosition() external view returns (uint32);
    function bridgedChainPosition() external view returns (uint32);
    function bridgedLanePosition() external view returns (uint32);
    function commitment() external view returns (bytes32);
    function getLaneInfo() external view returns (uint32,uint32,uint32,uint32);
}
