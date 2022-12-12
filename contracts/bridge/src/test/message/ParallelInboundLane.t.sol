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
import "../../message/ParallelInboundLane.sol";
import "../../spec/SourceChain.sol";
import "../mock/MockLightClient.sol";
import "../mock/NormalApp.sol";

contract ParallelInboundLandTest is DSTest, SourceChain {
    uint32 constant internal THIS_CHAIN_POS = 1;
    uint32 constant internal THIS_IN_LANE_POS = 3;
    uint32 constant internal BRIDGED_CHAIN_POS = 0;
    uint32 constant internal BRIDGED_OUT_LANE_POS = 2;

    MockLightClient public lightclient;
    ParallelInboundLane public inlane;
    NormalApp public app;
    address public self;

    function setUp() public {
        lightclient = new MockLightClient();
        inlane = new ParallelInboundLane(
            address(lightclient),
            THIS_CHAIN_POS,
            THIS_IN_LANE_POS,
            BRIDGED_CHAIN_POS,
            BRIDGED_OUT_LANE_POS
        );
        app = new NormalApp(address(0));
        self = address(this);
    }

    function test_constructor_args() public {
        assertEq(inlane.commitment(), bytes32(0));
    }

    function test_receive_message() public {
        address target = address(app);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        uint256 key = 0x0000000000000000000000000000000200000001000000030000000000000000;
        Message memory message = Message(key, MessagePayload({
            source: address(app),
            target: target,
            encoded: encoded
        }));
        assertEq(hash(message), 0xa27115ef7595101a3fccf934e06ebfdc53d951136b459fb11ead1bbbf85d1680);
        bytes32[32] memory proof = [
            bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
            bytes32(0xad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5),
            bytes32(0xb4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30),
            bytes32(0x21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85),
            bytes32(0xe58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344),
            bytes32(0x0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d),
            bytes32(0x887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968),
            bytes32(0xffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83),
            bytes32(0x9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af),
            bytes32(0xcefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0),
            bytes32(0xf9dc3e7fe016e050eff260334f18a5d4fe391d82092319f5964f2e2eb7c1c3a5),
            bytes32(0xf8b13a49e282f609c317a833fb8d976d11517c571d1221a265d25af778ecf892),
            bytes32(0x3490c6ceeb450aecdc82e28293031d10c7d73bf85e57bf041a97360aa2c5d99c),
            bytes32(0xc1df82d9c4b87413eae2ef048f94b4d3554cea73d92b0f7af96e0271c691e2bb),
            bytes32(0x5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc),
            bytes32(0xda7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2),
            bytes32(0x2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f),
            bytes32(0xe1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a),
            bytes32(0x5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0),
            bytes32(0xb46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0),
            bytes32(0xc65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2),
            bytes32(0xf4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9),
            bytes32(0x5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377),
            bytes32(0x4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652),
            bytes32(0xcdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef),
            bytes32(0x0abf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d),
            bytes32(0xb8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0),
            bytes32(0x838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e),
            bytes32(0x662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e),
            bytes32(0x388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322),
            bytes32(0x93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735),
            bytes32(0x8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9)
        ];
        inlane.receive_message(0xa8f477eb0e0ce8f6cc7f3a0f23f3d8075444eeb96f11bdca0c49b1355bd1e97b, hex"", message, proof);

        assertEq(inlane.commitment(), bytes32(0));
        assertTrue(inlane.dones(0));
        assertEq(inlane.fails(0), bytes32(0));
    }

    function test_receive_failed_message() public {
        bytes memory encoded = abi.encodeWithSignature("foo()");
        uint256 key = 0x0000000000000000000000000000000200000001000000030000000000000000;
        Message memory message = Message(key, MessagePayload({
            source: address(app),
            target: address(0),
            encoded: encoded
        }));
        assertEq(hash(message), 0xb8777365ea18812fb1b65d18dc46632a5fc4afbe946ce85006561fc9c740a1da);
        bytes32[32] memory proof = [
            bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
            bytes32(0xad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5),
            bytes32(0xb4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30),
            bytes32(0x21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85),
            bytes32(0xe58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344),
            bytes32(0x0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d),
            bytes32(0x887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968),
            bytes32(0xffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83),
            bytes32(0x9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af),
            bytes32(0xcefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0),
            bytes32(0xf9dc3e7fe016e050eff260334f18a5d4fe391d82092319f5964f2e2eb7c1c3a5),
            bytes32(0xf8b13a49e282f609c317a833fb8d976d11517c571d1221a265d25af778ecf892),
            bytes32(0x3490c6ceeb450aecdc82e28293031d10c7d73bf85e57bf041a97360aa2c5d99c),
            bytes32(0xc1df82d9c4b87413eae2ef048f94b4d3554cea73d92b0f7af96e0271c691e2bb),
            bytes32(0x5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc),
            bytes32(0xda7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2),
            bytes32(0x2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f),
            bytes32(0xe1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a),
            bytes32(0x5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0),
            bytes32(0xb46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0),
            bytes32(0xc65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2),
            bytes32(0xf4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9),
            bytes32(0x5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377),
            bytes32(0x4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652),
            bytes32(0xcdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef),
            bytes32(0x0abf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d),
            bytes32(0xb8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0),
            bytes32(0x838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e),
            bytes32(0x662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e),
            bytes32(0x388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322),
            bytes32(0x93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735),
            bytes32(0x8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9)
        ];
        inlane.receive_message(0x8df566d1b95b05289d787f8e5bb512908359b6679d67ec95f9b5450c289294ac, hex"", message, proof);

        assertEq(inlane.commitment(), bytes32(0));
        assertTrue(inlane.dones(0));
        assertEq(inlane.fails(0), hash(message));

        bool r = inlane.retry_failed_message(message);
        assertTrue(!r);
    }
}
