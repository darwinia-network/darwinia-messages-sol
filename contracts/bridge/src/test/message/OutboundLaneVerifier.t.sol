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
import "../../message/OutboundLaneVerifier.sol";
import "../mock/MockLightClient.sol";

contract OutboundLaneVerifierTest is DSTest {
    uint32 constant internal THIS_CHAIN_POS = 0;
    uint32 constant internal THIS_OUT_LANE_POS = 0;
    uint32 constant internal BRIDGED_CHAIN_POS = 1;
    uint32 constant internal BRIDGED_IN_LANE_POS = 1;

    MockLightClient public lightclient;
    OutboundLaneVerifier public verifier;

    function setUp() public {
        lightclient = new MockLightClient();
        uint256 lane_id = (uint(BRIDGED_IN_LANE_POS) << 64)
                        + (uint(BRIDGED_CHAIN_POS) << 96)
                        + (uint(THIS_OUT_LANE_POS) << 128)
                        + (uint(THIS_CHAIN_POS) << 160);
        assertEq(lane_id, uint256(0x0000000000000000000000000000000000000001000000010000000000000000));
        verifier = new OutboundLaneVerifier(address(lightclient), lane_id);
    }

    function test_contructor_args() public {
        (uint32 thisChainPosition,uint32 thisLanePosition,uint32 bridgedChainPosition,uint32 bridgedLanePosition) = verifier.getLaneInfo();
        assertEq(thisChainPosition, uint(THIS_CHAIN_POS));
        assertEq(thisLanePosition, uint(THIS_OUT_LANE_POS));
        assertEq(bridgedChainPosition, uint(BRIDGED_CHAIN_POS));
        assertEq(bridgedLanePosition, uint(BRIDGED_IN_LANE_POS));
    }

    function test_encode_message_key() public {
        assertEq(verifier.encodeMessageKey(1), uint256(0x0000000000000000000000000000000000000001000000010000000000000001));
    }

    function test_lane_id() public {
        assertEq(verifier.getLaneId(), uint256(0x0000000000000000000000000000000000000001000000010000000000000000));
    }
}
