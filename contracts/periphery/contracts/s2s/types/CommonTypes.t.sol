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

    // 1. One relayer
    // {
    //     relayers: [
    //         {
    //             relayer: 5CVJNZNyGFjj3NsYPV7xkDnLS3UKsCRSxWdKdDuCjbT7qWhH
    //             messages: {
    //                 begin: 536
    //                 end: 536
    //                 dispatchResults: 0x80
    //             }
    //         }
    //     ]
    //     lastConfirmedNonce: 535
    // }
    //
    // 2. No relayer
    // {
    //     relayers: []
    //     lastConfirmedNonce: 535
    // }
    function testDecodeInboundLaneData() public {
        bytes
            memory data = hex"0412c21427b9698f161d479724581747426dff88f0309b07aaa5879d3ea1f22b391802000000000000180200000000000004801702000000000000";
        CommonTypes.InboundLaneData memory inboundLaneData = CommonTypes
            .decodeInboundLaneData(data);

        assertEq(inboundLaneData.relayers.length, 1);
        assertEq(inboundLaneData.relayers[0].messages.begin, 536);
        assertEq(inboundLaneData.relayers[0].messages.end, 536);
        assertEq(inboundLaneData.relayers[0].messages.dispatch_results.bits, 1);
        assertEq0(
            inboundLaneData.relayers[0].messages.dispatch_results.result,
            hex"80"
        );
        assertEq(inboundLaneData.lastConfirmedNonce, 535);

        // No relayer, last delivered nonce is from lastConfirmedNonce
        bytes memory data2 = hex"00801702000000000000";
        CommonTypes.InboundLaneData memory inboundLaneData2 = CommonTypes
            .decodeInboundLaneData(data2);
        assertEq(inboundLaneData2.relayers.length, 0);
        assertEq(inboundLaneData2.lastConfirmedNonce, 535);
    }

    function testGetLastUnrewardedRelayerFromInboundLaneData() public {
        bytes
            memory data = hex"0412c21427b9698f161d479724581747426dff88f0309b07aaa5879d3ea1f22b391802000000000000180200000000000004801702000000000000";

        uint64 lastDeliveredNonce = CommonTypes
            .getLastDeliveredNonceFromInboundLaneData(data);

        assertTrue(lastDeliveredNonce == 536);

        // No relayer
        bytes memory data2 = hex"00801702000000000000";
        uint64 lastDeliveredNonce2 = CommonTypes
            .getLastDeliveredNonceFromInboundLaneData(data2);
        assertTrue(lastDeliveredNonce2 == 535);
    }

    function testBitVecU8() public {
        // 00 => bv[]
        CommonTypes.BitVecU8 memory r0 = CommonTypes.decodeBitVecU8(hex"00");
        assertEq(r0.bits, 0);
        assertEq0(r0.result, hex"");

        // 0400 => bv[0]
        CommonTypes.BitVecU8 memory r1 = CommonTypes.decodeBitVecU8(hex"0400");
        assertEq(r1.bits, 1);
        assertEq0(r1.result, hex"00");

        // 0480 => bv[1]
        CommonTypes.BitVecU8 memory r2 = CommonTypes.decodeBitVecU8(hex"0480");
        assertEq(r2.bits, 1);
        assertEq0(r2.result, hex"80");

        // 0800 => bv[0,0]
        CommonTypes.BitVecU8 memory r3 = CommonTypes.decodeBitVecU8(hex"0800");
        assertEq(r3.bits, 2);
        assertEq0(r3.result, hex"00");

        // 0800 => bv[1,0]
        CommonTypes.BitVecU8 memory r4 = CommonTypes.decodeBitVecU8(hex"0880");
        assertEq(r4.bits, 2);
        assertEq0(r4.result, hex"80");

        // 0ca0 => bv[1,0,1]
        CommonTypes.BitVecU8 memory r5_1 = CommonTypes.decodeBitVecU8(
            hex"0ca0"
        );
        assertEq(r5_1.bits, 3);
        assertEq0(r5_1.result, hex"a0");

        CommonTypes.BitVecU8 memory r5_2 = CommonTypes.decodeBitVecU8(
            hex"0ca01100"
        ); // 0ca0 => bv[1,0,1], 1100 is other data
        assertEq(r5_2.bits, 3);
        assertEq0(r5_2.result, hex"a0");

        // 1c56 => bv[0, 1, 0, 1, 0, 1, 1]
        CommonTypes.BitVecU8 memory r6 = CommonTypes.decodeBitVecU8(hex"1c56");
        assertEq(r6.bits, 7);
        assertEq0(r6.result, hex"56");

        // 2056 => bv[0, 1, 0, 1, 0, 1, 1, 0]
        CommonTypes.BitVecU8 memory r7 = CommonTypes.decodeBitVecU8(hex"2056");
        assertEq(r7.bits, 8);
        assertEq0(r7.result, hex"56");

        // 24d680 => bv[1, 1, 0, 1, 0, 1, 1, 0, 1]
        CommonTypes.BitVecU8 memory r8 = CommonTypes.decodeBitVecU8(
            hex"24d680"
        );
        assertEq(r8.bits, 9);
        assertEq0(r8.result, hex"d680");

        // 44565600 => bv[0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0]
        CommonTypes.BitVecU8 memory r9 = CommonTypes.decodeBitVecU8(
            hex"44565600"
        );
        assertEq(r9.bits, 17);
        assertEq0(r9.result, hex"565600");
    }
}
