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

import "../../interfaces/ICrossChainFilter.sol";
import "../../interfaces/IOutboundLane.sol";

contract HelixApp is ICrossChainFilter {

    modifier only_inlane() {
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function cross_chain_filter(uint32, uint32, address, bytes calldata) external pure override returns (bool) {
        // only remote helix app
        return true;
    }

    // source
    function lock() external payable {
        // 1. transfer token to backing
        // token.transferFrom(msg.sender, backing, amount)
        // 2. target issuing
        // outlane.send_message(target, abi.encodeWithSignature("mint()"))
    }

    // source
    function unlock() external only_inlane {
        // unlock token
        // token.transferFrom(backing, msg.sender, amount)
    }

    // target
    function mint() external only_inlane {
        // issuing mapping token
        // mapping_token.mint()
    }

    // target
    function burn() external {
        // 1. burn mapping_token
        // mapping_token.burn(msg.sender, amount)
        // 2. source unlock
        // outlane.send_message(source, abi.encodeWithSignature("unlock()"))
    }
}
