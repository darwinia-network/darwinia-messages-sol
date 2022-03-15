// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../../../lib/ds-test/src/test.sol";
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
            THIS_CHAIN_POS,
            THIS_OUT_LANE_POS,
            BRIDGED_CHAIN_POS,
            BRIDGED_IN_LANE_POS,
            1,
            0,
            0
        );
        app = new NormalApp(address(outlane));
        outlane.setFeeMarket(address(market));
        self = address(this);
        outlane.rely(address(app));
    }

    function test_constructor_args() public {
        assertEq(outlane.setter(), self);
        assertEq(outlane.fee_market(), address(market));
        assertEq(outlane.wards(address(app)), 1);
        (uint64 latest_received_nonce, uint64 latest_generated_nonce, uint64 oldest_unpruned_nonce) = outlane.outboundLaneNonce();
        assertEq(latest_received_nonce, 0);
        assertEq(latest_generated_nonce, 0);
        assertEq(oldest_unpruned_nonce, 1);
        assertEq(hevm.load(address(outlane), bytes32(uint(6))), bytes32(0));

        assertEq(outlane.commitment(), hex"abf32e0b787b02d3d682d36d36f9d3ee2888aa8ca1e44c3846ce95b08916c018");
        assertEq(outlane.message_size(), 0);
        OutboundLaneData memory data = outlane.data();
        assertEq(data.latest_received_nonce, 0);
    }

    function test_set_fee_market() public {
        outlane.setFeeMarket(address(1));
        assertEq(outlane.fee_market(), address(1));
    }

    function test_change_setter() public {
        outlane.changeSetter(address(1));
        assertEq(outlane.setter(), address(1));
    }

    function test_rely_deny() public {
        assertEq(outlane.wards(address(456)), 0);
        assertTrue(_tryRely(address(456)));
        assertEq(outlane.wards(address(456)), 1);
        assertTrue(_tryDeny(address(456)));
        assertEq(outlane.wards(address(456)), 0);

        outlane.changeSetter(address(1));

        assertTrue(!_tryRely(address(456)));
        assertTrue(!_tryDeny(address(456)));
    }

    function test_send_message() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);
        (uint64 latest_received_nonce, uint64 latest_generated_nonce, uint64 oldest_unpruned_nonce) = outlane.outboundLaneNonce();
        assertEq(latest_received_nonce, 0);
        assertEq(latest_generated_nonce, 1);
        assertEq(oldest_unpruned_nonce, 1);

        assertEq(outlane.message_size(), 1);
        OutboundLaneData memory data = outlane.data();
        assertEq(data.latest_received_nonce, 0);
        Message memory message = data.messages[0];
        assertEq(message.encoded_key, outlane.encodeMessageKey(1));
        assertEq(message.data.sourceAccount, address(app));
        assertEq(message.data.targetContract, target);
        assertEq(message.data.encodedHash, keccak256(encoded));
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

    //------------------------------------------------------------------
    // Helper functions
    //------------------------------------------------------------------

    function perform_send_message(address target, bytes memory encoded) public {
        uint fee = market.market_fee();
        app.send_message{value: fee}(target, encoded);
    }

    function perform_receive_messages_delivery_proof(uint64 begin, uint64 end, uint64 last_confirmed_nonce, uint64 last_delivered_nonce) public {
        DeliveredMessages memory messages = DeliveredMessages(begin, end, 0);
        UnrewardedRelayer[] memory relayers = new UnrewardedRelayer[](1);
        relayers[0] = UnrewardedRelayer(self, messages);
        InboundLaneData memory data = InboundLaneData(relayers, last_confirmed_nonce, last_delivered_nonce);
        outlane.receive_messages_delivery_proof(data, hex"");
    }

    function _tryRely(address usr) internal returns (bool ok) {
        (ok,) = address(outlane).call(abi.encodeWithSignature("rely(address)", usr));
    }

    function _tryDeny(address usr) internal returns (bool ok) {
        (ok,) = address(outlane).call(abi.encodeWithSignature("deny(address)", usr));
    }

}
