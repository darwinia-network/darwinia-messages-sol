// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../../../lib/ds-test/src/test.sol";
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
        assertEq(last_confirmed_nonce, 0);
        assertEq(last_delivered_nonce, 0);
        assertEq(relayer_range_front, 1);
        assertEq(relayer_range_back, 0);
        assertEq(inlane.relayers_size(), 0);
        assertEq(inlane.relayers_back(), address(0));
        InboundLaneData memory data = inlane.data();
        assertEq(data.relayers.length, 0);
        assertEq(data.last_confirmed_nonce, 0);
        assertEq(data.last_delivered_nonce, 0);
        assertEq(inlane.commitment(), hex"73f4b8865353519c091847f2c960c9aaaf72288b2d0ddcf97c04aa606be33876");
        assertEq(hevm.load(address(inlane), bytes32(uint(4))), bytes32(0));
    }

    function test_receive_messages_proof() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("foo()");
        inlane.receive_messages_proof(out_data, calldatas, hex"");

        InboundLaneData memory in_data = inlane.data();
        assertEq(in_data.last_confirmed_nonce, 0);
        assertEq(in_data.last_delivered_nonce, 1);
        assertEq(in_data.relayers.length, 1);
        UnrewardedRelayer memory relayer = in_data.relayers[0];
        assertEq(relayer.relayer, self);
        assertEq(relayer.messages.begin, 1);
        assertEq(relayer.messages.end, 1);
        assertEq(relayer.messages.dispatch_results, 1);

        assertEq(inlane.relayers_back(), self);
    }

    function testFail_receive_messages_proof0() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.latest_received_nonce = 1;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("foo()");
        inlane.receive_messages_proof(out_data, calldatas, hex"");
    }

    function testFail_receive_messages_proof1() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        bytes[] memory calldatas = new bytes[](2);
        calldatas[0] = abi.encodeWithSignature("foo()");
        calldatas[1] = abi.encodeWithSignature("foo()");
        inlane.receive_messages_proof(out_data, calldatas, hex"");
    }

    function testFail_receive_messages_proof2() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.messages[0].encoded_key = uint256(0x0000000000000000000000010000000000000000000000010000000000000002);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("foo()");
        inlane.receive_messages_proof(out_data, calldatas, hex"");
    }

    function testFail_receive_messages_proof3() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.messages[0].encoded_key = uint256(0x0000000000000000000000020000000000000000000000010000000000000001);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("foo()");
        inlane.receive_messages_proof(out_data, calldatas, hex"");
    }

    function testFail_receive_messages_proof4() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.messages[0].encoded_key = uint256(0x0000000000000000000000010000000100000000000000010000000000000001);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("foo()");
        inlane.receive_messages_proof(out_data, calldatas, hex"");
    }

    function testFail_receive_messages_proof5() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.messages[0].encoded_key = uint256(0x0000000000000000000000010000000000000001000000010000000000000001);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("foo()");
        inlane.receive_messages_proof(out_data, calldatas, hex"");
    }

    function testFail_receive_messages_proof6() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        out_data.messages[0].encoded_key = uint256(0x0000000000000000000000010000000000000000000000020000000000000001);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("foo()");
        inlane.receive_messages_proof(out_data, calldatas, hex"");
    }

    function test_receive_messages_proof_multi0() public {
        OutboundLaneData memory out_data = _multi_out_lane_data();
        bytes[] memory calldatas = new bytes[](3);
        calldatas[0] = abi.encodeWithSignature("foo()");
        calldatas[1] = abi.encodeWithSignature("foo()");
        calldatas[2] = abi.encodeWithSignature("foo()");
        inlane.receive_messages_proof(out_data, calldatas, hex"");

        InboundLaneData memory in_data = inlane.data();
        assertEq(in_data.last_confirmed_nonce, 0);
        assertEq(in_data.last_delivered_nonce, 3);
        assertEq(in_data.relayers.length, 1);
        UnrewardedRelayer memory relayer = in_data.relayers[0];
        assertEq(relayer.relayer, self);
        assertEq(relayer.messages.begin, 1);
        assertEq(relayer.messages.end, 3);
        assertEq(relayer.messages.dispatch_results, 7);

        assertEq(inlane.relayers_back(), self);
    }

    function test_receive_messages_proof_multi1() public {
        OutboundLaneData memory out_data = _out_lane_data(1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("foo()");
        inlane.receive_messages_proof(out_data, calldatas, hex"");

        out_data = _out_lane_data(2);
        inlane.receive_messages_proof(out_data, calldatas, hex"");

        out_data = _out_lane_data(3);
        inlane.receive_messages_proof(out_data, calldatas, hex"");

        InboundLaneData memory in_data = inlane.data();
        assertEq(in_data.last_confirmed_nonce, 0);
        assertEq(in_data.last_delivered_nonce, 3);
        assertEq(in_data.relayers.length, 1);
        UnrewardedRelayer memory relayer = in_data.relayers[0];
        assertEq(relayer.relayer, self);
        assertEq(relayer.messages.begin, 1);
        assertEq(relayer.messages.end, 3);
        assertEq(relayer.messages.dispatch_results, 7);

        assertEq(inlane.relayers_back(), self);
    }

    function _out_lane_data(uint64 nonce) internal view returns (OutboundLaneData memory) {
        address source = address(0);
        address target = address(app);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        bytes32 encodedHash = keccak256(encoded);
        MessagePayload memory payload = MessagePayload(source, target, encodedHash);
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
        bytes32 encodedHash = keccak256(encoded);
        MessagePayload memory payload = MessagePayload(source, target, encodedHash);
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
