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
import "../../spec/TargetChain.sol";

contract TargetChainTest is DSTest, TargetChain {

    function test_constants() public {
        assertEq(
            keccak256(abi.encodePacked(
                "InboundLaneData(UnrewardedRelayer[] relayers,uint64 last_confirmed_nonce,uint64 last_delivered_nonce)",
                "UnrewardedRelayer(address relayer,DeliveredMessages messages)",
                "DeliveredMessages(uint64 begin,uint64 end)"
                )
            ),
            INBOUNDLANEDATA_TYPEHASH
        );

        assertEq(
            keccak256(abi.encodePacked(
                "UnrewardedRelayer(address relayer,DeliveredMessages messages)",
                "DeliveredMessages(uint64 begin,uint64 end)"
                )
            ),
            UNREWARDEDRELAYER_TYPETASH
        );

        assertEq(
            keccak256(abi.encodePacked(
                "DeliveredMessages(uint64 begin,uint64 end)"
                )
            ),
            DELIVEREDMESSAGES_TYPETASH
        );
    }

    function test_default_hash() public {
        DeliveredMessages memory messages = DeliveredMessages(0, 0);
        assertEq(hash(messages), hex"33148df90c273ab183ac735a25ba9ad66a074875ba66b769c3964b06d137b424");
        UnrewardedRelayer[] memory relayers = new UnrewardedRelayer[](0);
        assertEq(hash(relayers), hex"290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563");
        InboundLaneData memory data = InboundLaneData(relayers, 0, 0);
        assertEq(hash(data), hex"ce1698f159eec0d8beb0e54dee44065d5e890d23fc233bdbab1c8c9b1ec31d21");
    }

    function test_hash() public {
        DeliveredMessages memory messages = DeliveredMessages(1, 1);
        assertEq(hash(messages), hex"dd58e13667ace4ca5285970186c78d869aaffac87b2917a08c6f249dc9c01631");
        UnrewardedRelayer[] memory relayers = new UnrewardedRelayer[](1);
        relayers[0] = UnrewardedRelayer(address(1), messages);
        assertEq(hash(relayers), hex"4c0ac8754ee095b2574aa2304366ed4228adb7bcf73984f93ab208beac7a3a44");
        InboundLaneData memory data = InboundLaneData(relayers, 0, 1);
        assertEq(hash(data), hex"b24a72eb10584e0a7b4f746aaac087c2e7d54d7d1b0a8edca344050c6219bdc7");
    }
}
