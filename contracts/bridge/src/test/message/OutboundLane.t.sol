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
import "../../message/OutboundLane.sol";
import "../../spec/TargetChain.sol";
import "../../spec/SourceChain.sol";
import "../mock/MockLightClient.sol";
import "../mock/MockFeeMarket.sol";
import "../mock/NormalApp.sol";

interface Hevm {
    function load(address c, bytes32 loc) external returns (bytes32 val);
}

contract OutboundLaneTest is DSTest, SourceChain, TargetChain {
    uint32 constant internal THIS_CHAIN_POS = 0;
    uint32 constant internal THIS_OUT_LANE_POS = 0;
    uint32 constant internal BRIDGED_CHAIN_POS = 1;
    uint32 constant internal BRIDGED_IN_LANE_POS = 1;

    Hevm internal hevm = Hevm(HEVM_ADDRESS);
    MockLightClient public lightclient;
    MockFeeMarket public market;
    OutboundLane public outlane;
    NormalApp public app;
    address public self;

    function setUp() public {
        lightclient = new MockLightClient();
        market = new MockFeeMarket();
        outlane = new OutboundLane(
            address(lightclient),
            address(market),
            THIS_CHAIN_POS,
            THIS_OUT_LANE_POS,
            BRIDGED_CHAIN_POS,
            BRIDGED_IN_LANE_POS,
            1,
            0,
            0
        );
        app = new NormalApp(address(outlane));
        self = address(this);
    }

    function test_constructor_args() public {
        assertEq(outlane.FEE_MARKET(), address(market));
        (uint64 latest_received_nonce, uint64 latest_generated_nonce, uint64 oldest_unpruned_nonce) = outlane.outboundLaneNonce();
        assertEq(latest_received_nonce, uint(0));
        assertEq(latest_generated_nonce, uint(0));
        assertEq(oldest_unpruned_nonce, uint(1));
        assertEq(hevm.load(address(outlane), bytes32(uint(6))), bytes32(0));

        assertEq(outlane.commitment(), hex"d66c5be543d08bf2f429a31cb6dd5d4c8ab76b11d6ecaa6ab6124e1370923ec1");
        assertEq(outlane.message_size(), uint(0));
        OutboundLaneDataStorage memory data = outlane.data();
        assertEq(data.latest_received_nonce, uint(0));
        assertEq(data.messages.length, uint(0));
    }

    function test_message_hash() public {
        MessagePayload memory payload = MessagePayload(0x7181932Da75beE6D3604F4ae56077B52fB0c5a3b, 0x0000000000000000000000000000000000000000, new bytes(0));
        assertEq(hash(payload), 0xf68a7103167104b132a65ee29f46cb238d61f3ca1813cc87155928bab0af5ac1);
    }

    function testFail_too_many_pending_messages() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        for (uint i=0; i<21; i++) {
            perform_send_message(target, encoded);
        }
    }

    function test_send_message() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        uint256 message_id = perform_send_message(target, encoded);
        (uint64 latest_received_nonce, uint64 latest_generated_nonce, uint64 oldest_unpruned_nonce) = outlane.outboundLaneNonce();
        assertEq(latest_received_nonce, uint(0));
        assertEq(latest_generated_nonce, uint(1));
        assertEq(oldest_unpruned_nonce, uint(1));

        assertEq(outlane.message_size(), uint(1));
        OutboundLaneDataStorage memory data = outlane.data();
        assertEq(data.latest_received_nonce, uint(0));
        MessagePayload memory payload = MessagePayload(address(app), target, encoded);
        MessageStorage memory message_storage = data.messages[0];
        assertEq(message_storage.encoded_key, message_id);
        assertEq(message_storage.payload_hash, hash(payload));
    }

    function test_receive_messages_delivery_proof() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);

        uint64 begin = 1;
        uint64 end = 1;
        uint64 last_confirmed_nonce = 0;
        uint64 last_delivered_nonce = 1;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);

        assert_empty_data(1, 1);
    }

    function testFail_receive_messages_delivery_proof0() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);

        uint64 begin = 1;
        uint64 end = 1;
        uint64 last_confirmed_nonce = 0;
        uint64 last_delivered_nonce = 0;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);
    }

    function testFail_receive_messages_delivery_proof1() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);

        uint64 begin = 1;
        uint64 end = 1;
        uint64 last_confirmed_nonce = 0;
        uint64 last_delivered_nonce = 2;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);
    }

    function testFail_receive_messages_delivery_proof2() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);

        uint64 begin = 1;
        uint64 end = 1;
        uint64 last_confirmed_nonce = 0;
        uint64 last_delivered_nonce = 256;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);
    }

    function testFail_receive_messages_delivery_proof3() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);

        uint64 begin = 1;
        uint64 end = 1;
        uint64 last_confirmed_nonce = 1;
        uint64 last_delivered_nonce = 1;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);
    }

    function testFail_receive_messages_delivery_proof4() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);

        uint64 begin = 2;
        uint64 end = 2;
        uint64 last_confirmed_nonce = 0;
        uint64 last_delivered_nonce = 1;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);
    }

    function testFail_receive_messages_delivery_proof5() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);

        uint64 begin = 2;
        uint64 end = 1;
        uint64 last_confirmed_nonce = 0;
        uint64 last_delivered_nonce = 1;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);
    }

    function test_send_multi_message() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);
        perform_send_message(target, encoded);
        perform_send_message(target, encoded);

        (uint64 latest_received_nonce, uint64 latest_generated_nonce, uint64 oldest_unpruned_nonce) = outlane.outboundLaneNonce();
        assertEq(latest_received_nonce, uint(0));
        assertEq(latest_generated_nonce, uint(3));
        assertEq(oldest_unpruned_nonce, uint(1));

        assertEq(outlane.message_size(), uint(3));
        OutboundLaneDataStorage memory data = outlane.data();
        assertEq(data.latest_received_nonce, uint(0));
        for(uint64 i = 0; i < 3; i++) {
            MessageStorage memory message = data.messages[i];
            MessagePayload memory payload = MessagePayload(address(app), target, encoded);
            assertEq(message.encoded_key, outlane.encodeMessageKey(i + 1));
            assertEq(message.payload_hash, hash(payload));
        }
    }

    function test_receive_multi_messages_delivery_proof0() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);
        perform_send_message(target, encoded);
        perform_send_message(target, encoded);

        uint64 begin = 1;
        uint64 end = 3;
        uint64 last_confirmed_nonce = 0;
        uint64 last_delivered_nonce = 3;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);

        assert_empty_data(3, 3);
    }

    function test_receive_multi_messages_delivery_proof1() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);
        perform_send_message(target, encoded);
        perform_send_message(target, encoded);

        uint64 begin = 1;
        uint64 end = 2;
        uint64 last_confirmed_nonce = 0;
        uint64 last_delivered_nonce = 2;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);
        assert_data(2, 3, 1);

        begin = 3;
        end = 3;
        last_confirmed_nonce = 0;
        last_delivered_nonce = 3;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);

        assert_empty_data(3, 3);
    }

    function testFail_receive_multi_messages_delivery_proof0() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);
        perform_send_message(target, encoded);
        perform_send_message(target, encoded);

        uint64 begin = 1;
        uint64 end = 3;
        uint64 last_confirmed_nonce = 0;
        uint64 last_delivered_nonce = 3;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);

        begin = 3;
        end = 3;
        last_confirmed_nonce = 0;
        last_delivered_nonce = 3;
        perform_receive_messages_delivery_proof(begin, end, last_confirmed_nonce, last_delivered_nonce);
    }

    //------------------------------------------------------------------
    // Helper functions
    //------------------------------------------------------------------

    function perform_send_message(address target, bytes memory encoded) public returns (uint256) {
        uint fee = market.market_fee();
        return app.send_message{value: fee}(target, encoded);
    }

    function perform_receive_messages_delivery_proof(uint64 begin, uint64 end, uint64 last_confirmed_nonce, uint64 last_delivered_nonce) public {
        DeliveredMessages memory messages = DeliveredMessages(begin, end);
        UnrewardedRelayer[] memory relayers = new UnrewardedRelayer[](1);
        relayers[0] = UnrewardedRelayer(self, messages);
        InboundLaneData memory data = InboundLaneData(relayers, last_confirmed_nonce, last_delivered_nonce);
        outlane.receive_messages_delivery_proof(data, hex"");
    }

    function assert_data(uint64 _latest_received_nonce, uint64 _latest_generated_nonce, uint64 _message_size) public {
        (uint64 latest_received_nonce, uint64 latest_generated_nonce, uint64 oldest_unpruned_nonce) = outlane.outboundLaneNonce();
        assertEq(latest_received_nonce, uint(_latest_received_nonce));
        assertEq(latest_generated_nonce, uint(_latest_generated_nonce));
        assertEq(oldest_unpruned_nonce, uint(1));

        assertEq(outlane.message_size(), uint(_message_size));
        OutboundLaneDataStorage memory data = outlane.data();
        assertEq(data.latest_received_nonce, uint(_latest_received_nonce));
    }

    function assert_empty_data(uint64 _latest_received_nonce, uint64 _latest_generated_nonce) public {
        (uint64 latest_received_nonce, uint64 latest_generated_nonce, uint64 oldest_unpruned_nonce) = outlane.outboundLaneNonce();
        assertEq(latest_received_nonce, uint(_latest_received_nonce));
        assertEq(latest_generated_nonce, uint(_latest_generated_nonce));
        assertEq(oldest_unpruned_nonce, uint(1));

        assertEq(outlane.message_size(), uint(0));
        OutboundLaneDataStorage memory data = outlane.data();
        assertEq(data.latest_received_nonce, uint(_latest_received_nonce));
    }

}
