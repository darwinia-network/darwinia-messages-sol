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
        verifier = new OutboundLaneVerifier(
            address(lightclient),
            THIS_CHAIN_POS,
            THIS_OUT_LANE_POS,
            BRIDGED_CHAIN_POS,
            BRIDGED_IN_LANE_POS
        );
    }

    function test_contructor_args() public {
        (uint32 bridgedLanePosition,uint32 bridgedChainPosition,uint32 thisLanePosition,uint32 thisChainPosition) = verifier.slot0();
        assertEq(bridgedLanePosition, uint(BRIDGED_IN_LANE_POS));
        assertEq(bridgedChainPosition, uint(BRIDGED_CHAIN_POS));
        assertEq(thisLanePosition, uint(THIS_OUT_LANE_POS));
        assertEq(thisChainPosition, uint(THIS_CHAIN_POS));

        (thisChainPosition, thisLanePosition, bridgedChainPosition, bridgedLanePosition) = verifier.getLaneInfo();
        assertEq(thisChainPosition, uint(THIS_CHAIN_POS));
        assertEq(thisLanePosition, uint(THIS_OUT_LANE_POS));
        assertEq(bridgedChainPosition, uint(BRIDGED_CHAIN_POS));
        assertEq(bridgedLanePosition, uint(BRIDGED_IN_LANE_POS));
    }

    function test_encode_message_key() public {
        assertEq(verifier.encodeMessageKey(1), uint256(0x0000000000000000000000000000000000000001000000010000000000000001));
    }
}
