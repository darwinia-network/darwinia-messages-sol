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
import "../../message/ParallelOutboundLane.sol";
import "../../spec/SourceChain.sol";
import "../mock/MockLightClient.sol";
import "../mock/NormalApp.sol";

contract ParallelOutboundLaneTest is DSTest, SourceChain {
    uint32 constant internal THIS_CHAIN_POS = 0;
    uint32 constant internal THIS_OUT_LANE_POS = 2;
    uint32 constant internal BRIDGED_CHAIN_POS = 1;
    uint32 constant internal BRIDGED_IN_LANE_POS = 3;

    ParallelOutboundLane public outlane;
    NormalApp public app;
    address public self;

    function setUp() public {
        uint256 lane_id = (uint(BRIDGED_IN_LANE_POS) << 64)
                        + (uint(BRIDGED_CHAIN_POS) << 96)
                        + (uint(THIS_OUT_LANE_POS) << 128)
                        + (uint(THIS_CHAIN_POS) << 160);
        outlane = new ParallelOutboundLane(lane_id);
        app = new NormalApp(address(outlane));
        self = address(this);
    }

    function test_constructor_args() public {
        assertEq(outlane.commitment(), 0x27ae5ba08d7291c96c8cbddcc148bf48a6d68c7974b94356f53754ef6171d757);
        assertEq(outlane.message_size(), uint(0));
        bytes32[32] memory branch = outlane.imt_branch();
        for (uint i = 0; i < 32; i++) {
            assertEq(branch[i], bytes32(0));
        }
    }

    function test_send_message() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        uint256 nonce = perform_send_message(target, encoded);
        assertEq(nonce, 0);
        assertEq(outlane.message_size(), uint(1));
        bytes32 msg_hash = hash(
            Message(outlane.encodeMessageKey(0), MessagePayload({
                source: address(app),
                target: target,
                encoded: encoded
            }))
        );

        assertEq(outlane.encodeMessageKey(0), 0x0000000000000000000000000000000200000001000000030000000000000000);
        assertEq(msg_hash, 0x92d82c01f47742df2d289dd6a7eff88e6bca95f5c94ed3a4a9823247aadce4ae);
        assertEq(outlane.commitment(), 0xaf1895aef5d259c5550219c9f02e0a670416f2c69b1c5040f442ba7dc80b725d);
        bytes32[32] memory branch = outlane.imt_branch();
        assertEq(branch[0], msg_hash);
    }

    function test_send_multi_message() public {
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        perform_send_message(target, encoded);
        perform_send_message(target, encoded);
        perform_send_message(target, encoded);

        MessagePayload memory payload = MessagePayload(address(app), target, encoded);
        bytes32 msg_hash1 = hash(Message(outlane.encodeMessageKey(0), payload));
        assertEq(msg_hash1, 0x92d82c01f47742df2d289dd6a7eff88e6bca95f5c94ed3a4a9823247aadce4ae);
        bytes32 msg_hash2 = hash(Message(outlane.encodeMessageKey(1), payload));
        assertEq(msg_hash2, 0xe62da3ba053e2beff830250dfda483d26af912e254774c9f9e90ce67eb26834f);
        bytes32 msg_hash3 = hash(Message(outlane.encodeMessageKey(2), payload));
        assertEq(msg_hash3, 0xf31763f2dd627e6f69cd69e7dabde863936fb352f75aef72aae954a09c4b1819);

        assertEq(outlane.message_size(), uint(3));
        assertEq(outlane.commitment(), 0xc4504c558fcc759fe2cf35bc9ba69132c093263d4e17357ae48d1ece7482800a);
    }

    function perform_send_message(address target, bytes memory encoded) public returns (uint256) {
        return app.send_message(target, encoded);
    }
}
