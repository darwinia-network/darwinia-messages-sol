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

import "../test.sol";
import "../../message/InboundLane.sol";
import "../../spec/TargetChain.sol";
import "../../spec/SourceChain.sol";
import "../mock/MockLightClient.sol";
import "../mock/MockFeeMarket.sol";
import "../mock/NormalApp.sol";

interface Hevm {
    function load(address c, bytes32 loc) external returns (bytes32 val);
}

contract InboundLandTest is DSTest, SourceChain, TargetChain {
    uint32 constant internal THIS_CHAIN_POS = 0;
    uint32 constant internal THIS_IN_LANE_POS = 1;
    uint32 constant internal BRIDGED_CHAIN_POS = 1;
    uint32 constant internal BRIDGED_OUT_LANE_POS = 0;

    Hevm internal hevm = Hevm(HEVM_ADDRESS);
    MockLightClient public lightclient;
    MockFeeMarket public market;
    InboundLane public inlane;
    NormalApp public app;
    address public self;

    function setUp() public {
        lightclient = new MockLightClient();
        market = new MockFeeMarket();
        inlane = new InboundLane(
            address(lightclient),
            THIS_CHAIN_POS,
            THIS_IN_LANE_POS,
            BRIDGED_CHAIN_POS,
            BRIDGED_OUT_LANE_POS,
            0,
            0
        );
        app = new NormalApp(address(0));
        self = address(this);
    }

    function test_constructor_args() public {
        (uint64 last_confirmed_nonce, uint64 last_delivered_nonce, uint64 relayer_range_front, uint64 relayer_range_back) = inlane.inboundLaneNonce();
        assertEq(last_confirmed_nonce, uint(0));
        assertEq(last_delivered_nonce, uint(0));
        assertEq(relayer_range_front, uint(1));
        assertEq(relayer_range_back, uint(0));
        assertEq(inlane.relayers_size(), uint(0));
        assertEq(inlane.relayers_back(), address(0));
        InboundLaneData memory data = inlane.data();
        assertEq(data.relayers.length, 0);
        assertEq(data.last_confirmed_nonce, uint(0));
        assertEq(data.last_delivered_nonce, uint(0));
        assertEq(inlane.commitment(), hex"66b5278e1f7507462f2157f72f3ce409601f7ca3fa7092dc8aaa869467b38413");
        assertEq(hevm.load(address(inlane), bytes32(uint(4))), bytes32(0));
    }

    function test_receive_messages_proof() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        inlane.receive_messages_proof(out_data, hex"");

        InboundLaneData memory in_data = inlane.data();
        assertEq(in_data.last_confirmed_nonce, uint(0));
        assertEq(in_data.last_delivered_nonce, uint(1));
        assertEq(in_data.relayers.length, 1);
        UnrewardedRelayer memory relayer = in_data.relayers[0];
        assertEq(relayer.relayer, self);
        assertEq(relayer.messages.begin, uint(1));
        assertEq(relayer.messages.end, uint(1));

        assertEq(inlane.relayers_back(), self);
    }

    function testFail_receive_messages_proof0() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.latest_received_nonce = 1;
        inlane.receive_messages_proof(out_data, hex"");
    }

    function testFail_receive_messages_proof1() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.messages[0].encoded_key = uint256(0x0000000000000000000000010000000000000000000000010000000000000002);
        inlane.receive_messages_proof(out_data, hex"");
    }

    function testFail_receive_messages_proof2() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.messages[0].encoded_key = uint256(0x0000000000000000000000020000000000000000000000010000000000000001);
        inlane.receive_messages_proof(out_data, hex"");
    }

    function testFail_receive_messages_proof3() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.messages[0].encoded_key = uint256(0x0000000000000000000000010000000100000000000000010000000000000001);
        inlane.receive_messages_proof(out_data, hex"");
    }

    function testFail_receive_messages_proof4() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.messages[0].encoded_key = uint256(0x0000000000000000000000010000000000000001000000010000000000000001);
        inlane.receive_messages_proof(out_data, hex"");
    }

    function testFail_receive_messages_proof5() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.messages[0].encoded_key = uint256(0x0000000000000000000000010000000000000000000000020000000000000001);
        inlane.receive_messages_proof(out_data, hex"");
    }

    function test_receive_messages_proof_multi0() public {
        OutboundLaneData memory out_data = _multi_out_lane_data();
        inlane.receive_messages_proof(out_data, hex"");

        InboundLaneData memory in_data = inlane.data();
        assertEq(in_data.last_confirmed_nonce, uint(0));
        assertEq(in_data.last_delivered_nonce, uint(3));
        assertEq(in_data.relayers.length, 1);
        UnrewardedRelayer memory relayer = in_data.relayers[0];
        assertEq(relayer.relayer, self);
        assertEq(relayer.messages.begin, uint(1));
        assertEq(relayer.messages.end, uint(3));

        assertEq(inlane.relayers_back(), self);
    }

    function test_receive_messages_proof_multi1() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        inlane.receive_messages_proof(out_data, hex"");

        out_data = _out_lane_data(2);
        inlane.receive_messages_proof(out_data, hex"");

        out_data = _out_lane_data(3);
        inlane.receive_messages_proof(out_data, hex"");

        InboundLaneData memory in_data = inlane.data();
        assertEq(in_data.last_confirmed_nonce, uint(0));
        assertEq(in_data.last_delivered_nonce, uint(3));
        assertEq(in_data.relayers.length, 1);
        UnrewardedRelayer memory relayer = in_data.relayers[0];
        assertEq(relayer.relayer, self);
        assertEq(relayer.messages.begin, uint(1));
        assertEq(relayer.messages.end, uint(3));

        assertEq(inlane.relayers_back(), self);
    }

    function _out_lane_data(uint64 nonce) internal view returns (OutboundLaneData memory) {
        address source = address(0);
        address target = address(app);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        MessagePayload memory payload = MessagePayload(source, target, encoded);
        uint256 encoded_key = inlane.encodeMessageKey(nonce);
        Message memory message = Message(encoded_key, payload);
        Message[] memory messages = new Message[](1);
        messages[0] = message;
        return OutboundLaneData(0, messages);
    }

    function _multi_out_lane_data() internal view returns (OutboundLaneData memory) {
        address source = address(0);
        address target = address(app);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        MessagePayload memory payload = MessagePayload(source, target, encoded);
        uint256 encoded_key = inlane.encodeMessageKey(1);
        Message memory message = Message(encoded_key, payload);
        Message memory message1 = Message(encoded_key + 1, payload);
        Message memory message2 = Message(encoded_key + 2, payload);
        Message[] memory messages = new Message[](3);
        messages[0] = message;
        messages[1] = message1;
        messages[2] = message2;
        return OutboundLaneData(0, messages);
    }
}
