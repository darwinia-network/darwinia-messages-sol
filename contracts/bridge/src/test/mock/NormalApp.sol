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

import "../../interfaces/ICrossChainFilter.sol";
import "../../interfaces/IOutboundLane.sol";

contract NormalApp is ICrossChainFilter {

    IOutboundLane outlane;

    constructor(address _outlane) {
        outlane = IOutboundLane(_outlane);
    }

    receive() external payable {}

    fallback() external payable {}

    function cross_chain_filter(uint32, uint32, address, bytes calldata) external pure override returns (bool) {
        return true;
    }

    function send_message(address target, bytes calldata encoded) external payable returns (uint256) {
        return outlane.send_message{value: msg.value}(target, encoded);
    }
}
