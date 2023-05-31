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

interface IRequestOracle {
    function getLastRequestId() external view returns (uint64 requestId);
    function getRequestFee() external view returns (address feeToken, uint256 requestFee);
    function requestHash(uint256 block_number) external returns (uint64 requestId);
    function isRequestComplete(uint64 requestId) external view returns (bool isCompleted);
    function hashOf(uint64 requestId) external view returns (bytes32 hash);
}
