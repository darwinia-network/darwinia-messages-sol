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
import "../../message/BaseOutboundLane.sol";
import "../../spec/SourceChain.sol";
import "../mock/MockLightClient.sol";
import "../mock/NormalApp.sol";

contract BaseOutboundLaneTest is DSTest, SourceChain {
    uint32 constant internal THIS_CHAIN_POS = 0;
    uint32 constant internal THIS_OUT_LANE_POS = 2;
    uint32 constant internal BRIDGED_CHAIN_POS = 1;
    uint32 constant internal BRIDGED_IN_LANE_POS = 3;

    MockLightClient public lightclient;
    BaseOutboundLane public outlane;
    NormalApp public app;
    address public self;

    function setUp() public {
        lightclient = new MockLightClient();
        outlane = new BaseOutboundLane(
            address(lightclient),
            THIS_CHAIN_POS,
            THIS_OUT_LANE_POS,
            BRIDGED_CHAIN_POS,
            BRIDGED_IN_LANE_POS
        );
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
        assertEq(nonce, 1);
        assertEq(outlane.message_size(), uint(1));
        bytes32 msg_hash = hash(
            Message(outlane.encodeMessageKey(1), MessagePayload({
                source: address(app),
                target: target,
                encoded: encoded
            }))
        );
        assertEq(outlane.encodeMessageKey(1), 0x0000000000000000000000000000000200000001000000030000000000000001);
        assertEq(msg_hash, 0x24df9438f702fd58f57a5307c88714bbc1553b63c024de9ea89d8c9ab9e0d576);
        assertEq(outlane.commitment(), 0x98ca2eb3c08322f6837586afaf34eead83377184f0d8570f92b9953fcf8cc614);
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
        bytes32 msg_hash1 = hash(Message(outlane.encodeMessageKey(1), payload));
        assertEq(msg_hash1, 0x24df9438f702fd58f57a5307c88714bbc1553b63c024de9ea89d8c9ab9e0d576);
        bytes32 msg_hash2 = hash(Message(outlane.encodeMessageKey(2), payload));
        assertEq(msg_hash2, 0xbc2839cbd650480f79654999fcd75b82208084506a2a99bc1c7a28cdae0b3d37);
        bytes32 msg_hash3 = hash(Message(outlane.encodeMessageKey(3), payload));
        assertEq(msg_hash3, 0x426538a3b42c1fb97863a6847aa9a45bf80479a8011a1dcabc3bfd802e567d0b);

        assertEq(outlane.message_size(), uint(3));
        assertEq(outlane.commitment(), 0x65ab04ae1aa3d58e20ee1d954dc21e1e92fb429701d218583b80c4de2638bf92);
    }

    function perform_send_message(address target, bytes memory encoded) public returns (uint256) {
        return app.send_message(target, encoded);
    }
}
