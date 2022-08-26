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
        assertEq(hash(messages), hex"e214f0b3ce178f693b18c52919edc29ffe935343c76b17704b410d8c882e74da");
        UnrewardedRelayer[] memory relayers = new UnrewardedRelayer[](0);
        assertEq(hash(relayers), hex"290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563");
        InboundLaneData memory data = InboundLaneData(relayers, 0, 0);
        assertEq(hash(data), hex"66b5278e1f7507462f2157f72f3ce409601f7ca3fa7092dc8aaa869467b38413");

    }

    function test_hash() public {
        DeliveredMessages memory messages = DeliveredMessages(1, 1);
        assertEq(hash(messages), hex"8c4376658fb7931861c44cd7fd187ebfe2ac3c956963cedf369ef4de343799dc");
        UnrewardedRelayer[] memory relayers = new UnrewardedRelayer[](1);
        relayers[0] = UnrewardedRelayer(address(1), messages);
        assertEq(hash(relayers), hex"2e004505eaef4472a04cc84b407767b2e1a8bb43e7ea67299eca2f16c7e513cd");
        InboundLaneData memory data = InboundLaneData(relayers, 0, 1);
        assertEq(hash(data), hex"d0ef2e272b80d26edcfc1d6b3603ca1778bf9015f17c5214a3554f5394ac9124");
    }

}
