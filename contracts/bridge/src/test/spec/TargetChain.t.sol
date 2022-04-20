// SPDX-License-Identifier: Apache-2.0

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
                "DeliveredMessages(uint64 begin,uint64 end,uint256 dispatch_results)"
                )
            ),
            INBOUNDLANEDATA_TYPEHASH
        );

        assertEq(
            keccak256(abi.encodePacked(
                "UnrewardedRelayer(address relayer,DeliveredMessages messages)"
                )
            ),
            UNREWARDEDRELAYER_TYPETASH
        );

        assertEq(
            keccak256(abi.encodePacked(
                "DeliveredMessages(uint64 begin,uint64 end,uint256 dispatch_results)"
                )
            ),
            DELIVEREDMESSAGES_TYPETASH
        );
    }

    function test_default_hash() public {
        DeliveredMessages memory messages = DeliveredMessages(0, 0, 0);
        assertEq(hash(messages), hex"e214f0b3ce178f693b18c52919edc29ffe935343c76b17704b410d8c882e74da");
        UnrewardedRelayer[] memory relayers = new UnrewardedRelayer[](0);
        assertEq(hash(relayers), hex"290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563");
        InboundLaneData memory data = InboundLaneData(relayers, 0, 0);
        assertEq(hash(data), hex"66b5278e1f7507462f2157f72f3ce409601f7ca3fa7092dc8aaa869467b38413");

    }

    function test_hash() public {
        DeliveredMessages memory messages = DeliveredMessages(1, 1, 1);
        assertEq(hash(messages), hex"8c4376658fb7931861c44cd7fd187ebfe2ac3c956963cedf369ef4de343799dc");
        UnrewardedRelayer[] memory relayers = new UnrewardedRelayer[](1);
        relayers[0] = UnrewardedRelayer(address(1), messages);
        assertEq(hash(relayers), hex"605bf17a2b6c7a6caa432b4cc39ad3b2400f479f9cde70ff1efbfb1c46dc46cb");
        InboundLaneData memory data = InboundLaneData(relayers, 0, 1);
        assertEq(hash(data), hex"8f802bcb220cf6dce5c09e9cf80f9e75c276bd7dd5b03c3e354ef76ad3f09845");
    }

}
