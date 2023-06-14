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

import "../../interfaces/IFeedOracle.sol";

contract FeedOracle {
    IFeedOracle public oracle;

    constructor(address oracle_) {
        oracle = IFeedOracle(oracle_);
    }

    function _latest_block_number() internal view returns (uint256) {
        (uint256 block_number,) = oracle.latestAnswer();
        return block_number;
    }

    function _latest_state_root() internal view returns (bytes32) {
        (,bytes32 state_root) = oracle.latestAnswer();
        return state_root;
    }
}