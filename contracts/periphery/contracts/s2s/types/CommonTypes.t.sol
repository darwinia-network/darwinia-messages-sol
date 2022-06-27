// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../ds-test/test.sol";
import "./CommonTypes.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract CommonTypesTest is DSTest {
    function setUp() public {}

    function testGetLastRelayerFromVec() public {
        bytes
            memory data = hex"0cf41d3260d736f5b3db8a6351766e97619ea35972546a5f850bbf0b27764abe030010a5d4e8000000000000000000000000d6117e030000000000000000000000d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d00743ba40b000000000000000000000000d6117e030000000000000000000000a09c083ca783d2f2621ae7e2ee8d285c8cf103303f309b031521967db57bda140098f73e5d010000000000000000000000c817a8040000000000000000000000";
        CommonTypes.Relayer memory relayer = CommonTypes.getLastRelayerFromVec(
            data
        );
        assertTrue(relayer.fee == 20000000000);
    }

    function testDecodeOutboundLaneData() public {
        bytes
            memory data = hex"010000000000000000000000000000000c00000000000000";
        CommonTypes.OutboundLaneData memory outboundLaneData = CommonTypes
            .decodeOutboundLaneData(data);
        assertTrue(outboundLaneData.latestGeneratedNonce == 12);
    }

    function testGetLastUnrewardedRelayerFromInboundLaneData() public {
        bytes
            memory data = hex"0412c21427b9698f161d479724581747426dff88f0309b07aaa5879d3ea1f22b391802000000000000180200000000000004801702000000000000";
        // 04 12c21427b9698f161d479724581747426dff88f0309b07aaa5879d3ea1f22b39 1802000000000000180200000000000004 801702000000000000
        // {
        //     relayers: [
        //         {
        //             relayer: 5CVJNZNyGFjj3NsYPV7xkDnLS3UKsCRSxWdKdDuCjbT7qWhH
        //             messages: {
        //                 begin: 536
        //                 end: 536
        //                 dispatchResults: 0b00000001
        //             }
        //         }
        //     ]
        //     lastConfirmedNonce: 535
        // }
        uint64 lastDeliveredNonce = CommonTypes
            .getLastDeliveredNonceFromInboundLaneData(data);
        
        // TODO: decode relayer
        // assertTrue(relayer.messages.begin == 536);
        // assertTrue(relayer.messages.end == 536);
        // console.logBytes1(relayer.messages.dispatch_results); // Why 0x04?
        assertTrue(lastDeliveredNonce == 536);
        
        // No relayer, last delivered nonce is from lastConfirmedNonce
        // {
        //     relayers: []
        //     lastConfirmedNonce: 535
        // }
        bytes memory data2 = hex"00801702000000000000";
        uint64 lastDeliveredNonce2 = CommonTypes
            .getLastDeliveredNonceFromInboundLaneData(data2);
        assertTrue(lastDeliveredNonce2 == 535);
    }
}
