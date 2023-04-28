// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../ds-test/test.sol";
import "./CommonTypes.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract CommonTypesTest is DSTest {
    function setUp() public {}

    function testGetLastRelayerFromVec() public {
        bytes
            memory data = hex"0c5af9a1be7bc22f9a6b2ce90acd69c23dceeb23c2000080186bf13a5e2b0000000000000000009814440dab2108000000000000001678a973ae9750d25c126cdbce891bb8cfacd520000080186bf13a5e2b000000000000000000809e483072ac08000000000000000b001c95e86d64c1ad6e43944c568a6c31b53887000080186bf13a5e2b000000000000000000809e483072ac0800000000000000";
        CommonTypes.Relayer memory relayer = CommonTypes.getLastRelayerFromVec(
            data
        );
        assertEq(relayer.id, hex"0b001c95E86D64C1Ad6e43944C568A6C31b53887");
        assertEq(relayer.collateral, 800000000000000000000);
        assertTrue(relayer.fee == 160000000000000000000);
    }

    function testDecodeOutboundLaneData() public {
        bytes
            memory data = hex"040000000000000004000000000000000400000000000000";
        CommonTypes.OutboundLaneData memory outboundLaneData = CommonTypes
            .decodeOutboundLaneData(data);
        assertTrue(outboundLaneData.oldestUnprunedNonce == 4);
        assertTrue(outboundLaneData.latestReceivedNonce == 4);
        assertTrue(outboundLaneData.latestGeneratedNonce == 4);
    }

    // 1. One relayer
    // {
    //   relayers: [
    //     {
    //       relayer: 0x5af9A1Be7bc22f9a6b2cE90acd69c23DCEEB23C2
    //       messages: {
    //         begin: 1
    //         end: 1
    //         dispatchResults: 0b00000000
    //       }
    //     }
    //   ]
    //   lastConfirmedNonce: 0
    // }
    //
    // 2. No relayer
    // {
    //     relayers: []
    //     lastConfirmedNonce: 535
    // }
    function testDecodeInboundLaneData() public {
        bytes
            memory data = hex"045af9a1be7bc22f9a6b2ce90acd69c23dceeb23c20100000000000000010000000000000004000000000000000000";
        CommonTypes.InboundLaneData memory inboundLaneData = CommonTypes
            .decodeInboundLaneData(data);

        assertEq(inboundLaneData.relayers.length, 1);
        assertEq(
            inboundLaneData.relayers[0].relayer,
            0x5af9A1Be7bc22f9a6b2cE90acd69c23DCEEB23C2
        );
        assertEq(inboundLaneData.relayers[0].messages.begin, 1);
        assertEq(inboundLaneData.relayers[0].messages.end, 1);
        assertEq(inboundLaneData.relayers[0].messages.dispatchResults.bits, 1);
        assertEq0(
            inboundLaneData.relayers[0].messages.dispatchResults.result,
            hex"00"
        );
        assertEq(inboundLaneData.lastConfirmedNonce, 0);

        // No relayer, last delivered nonce is from lastConfirmedNonce
        bytes memory data2 = hex"00801702000000000000";
        CommonTypes.InboundLaneData memory inboundLaneData2 = CommonTypes
            .decodeInboundLaneData(data2);
        assertEq(inboundLaneData2.relayers.length, 0);
        assertEq(inboundLaneData2.lastConfirmedNonce, 535);
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

        // 0880 => bv[1,0]
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
