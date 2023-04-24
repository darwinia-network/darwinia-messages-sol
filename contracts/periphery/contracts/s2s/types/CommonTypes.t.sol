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
            memory data = hex"0c0b001c95e86d64c1ad6e43944c568a6c31b538870000907b984f02ca30000000000000000000dcce86b42ad00000000000000000f24ff3a9cf04c71dbc94d0b566f7a27b94566cac0000907b984f02ca300000000000000000009814440dab2108000000000000001678a973ae9750d25c126cdbce891bb8cfacd5200000907b984f02ca300000000000000000009814440dab210800000000000000";
        CommonTypes.Relayer memory relayer = CommonTypes.getLastRelayerFromVec(
            data
        );
        assertTrue(relayer.fee == 150000000000000000000);
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
    //                 dispatchResults: 0x0480
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
        assertEq(inboundLaneData.relayers[0].messages.dispatchResults.bits, 1);
        assertEq0(
            inboundLaneData.relayers[0].messages.dispatchResults.result,
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

    // https://github.com/darwinia-network/darwinia-messages-substrate/blob/main/primitives/messages/src/lib.rs#L342-L349
    function testDecodeInboundLaneData2() public {
        // single relayer, multiple messages
        // (1, 128u8)
        bytes
            memory data0 = hex"047d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae39010000000000000001000000000000000102ffffffffffffffffffffffffffffffff8000000000000000";
        CommonTypes.InboundLaneData memory inboundLaneData0 = CommonTypes
            .decodeInboundLaneData(data0);
        assertEq(inboundLaneData0.relayers.length, 1);
        assertEq(
            inboundLaneData0.relayers[0].messages.dispatchResults.bits,
            128
        );
        assertEq(
            inboundLaneData0.relayers[0].relayer,
            0x7d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae39
        );
        assertEq(inboundLaneData0.lastConfirmedNonce, 128);

        // multiple relayers, single message per relayer
        // (128u8, 128u8)
        bytes
            memory data1 = hex"01027d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390100000000000000010000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390200000000000000020000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390300000000000000030000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390400000000000000040000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390500000000000000050000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390600000000000000060000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390700000000000000070000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390800000000000000080000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390900000000000000090000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390a000000000000000a0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390b000000000000000b0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390c000000000000000c0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390d000000000000000d0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390e000000000000000e0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390f000000000000000f0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391000000000000000100000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391100000000000000110000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391200000000000000120000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391300000000000000130000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391400000000000000140000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391500000000000000150000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391600000000000000160000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391700000000000000170000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391800000000000000180000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391900000000000000190000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391a000000000000001a0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391b000000000000001b0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391c000000000000001c0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391d000000000000001d0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391e000000000000001e0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae391f000000000000001f0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392000000000000000200000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392100000000000000210000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392200000000000000220000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392300000000000000230000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392400000000000000240000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392500000000000000250000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392600000000000000260000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392700000000000000270000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392800000000000000280000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392900000000000000290000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392a000000000000002a0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392b000000000000002b0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392c000000000000002c0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392d000000000000002d0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392e000000000000002e0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae392f000000000000002f0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393000000000000000300000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393100000000000000310000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393200000000000000320000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393300000000000000330000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393400000000000000340000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393500000000000000350000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393600000000000000360000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393700000000000000370000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393800000000000000380000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393900000000000000390000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393a000000000000003a0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393b000000000000003b0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393c000000000000003c0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393d000000000000003d0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393e000000000000003e0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae393f000000000000003f0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394000000000000000400000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394100000000000000410000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394200000000000000420000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394300000000000000430000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394400000000000000440000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394500000000000000450000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394600000000000000460000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394700000000000000470000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394800000000000000480000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394900000000000000490000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394a000000000000004a0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394b000000000000004b0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394c000000000000004c0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394d000000000000004d0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394e000000000000004e0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae394f000000000000004f0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395000000000000000500000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395100000000000000510000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395200000000000000520000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395300000000000000530000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395400000000000000540000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395500000000000000550000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395600000000000000560000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395700000000000000570000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395800000000000000580000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395900000000000000590000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395a000000000000005a0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395b000000000000005b0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395c000000000000005c0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395d000000000000005d0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395e000000000000005e0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae395f000000000000005f0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396000000000000000600000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396100000000000000610000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396200000000000000620000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396300000000000000630000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396400000000000000640000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396500000000000000650000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396600000000000000660000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396700000000000000670000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396800000000000000680000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396900000000000000690000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396a000000000000006a0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396b000000000000006b0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396c000000000000006c0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396d000000000000006d0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396e000000000000006e0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae396f000000000000006f0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397000000000000000700000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397100000000000000710000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397200000000000000720000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397300000000000000730000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397400000000000000740000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397500000000000000750000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397600000000000000760000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397700000000000000770000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397800000000000000780000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397900000000000000790000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397a000000000000007a0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397b000000000000007b0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397c000000000000007c0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397d000000000000007d0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397e000000000000007e0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae397f000000000000007f0000000000000004807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae398000000000000000800000000000000004808000000000000000";
        CommonTypes.InboundLaneData memory inboundLaneData1 = CommonTypes
            .decodeInboundLaneData(data1);
        assertEq(inboundLaneData1.relayers.length, 128);
        for (uint i = 0; i < inboundLaneData1.relayers.length; i++) {
            assertEq(
                inboundLaneData1.relayers[i].messages.dispatchResults.bits,
                1
            );
            assertEq(
                inboundLaneData1.relayers[i].relayer,
                0x7d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae39
            );
        }

        assertEq(inboundLaneData1.lastConfirmedNonce, 128);

        // several messages per relayer
        // (13u8, 128u8)
        bytes
            memory data2 = hex"347d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390100000000000000010000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390200000000000000020000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390300000000000000030000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390400000000000000040000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390500000000000000050000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390600000000000000060000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390700000000000000070000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390800000000000000080000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390900000000000000090000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390a000000000000000a0000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390b000000000000000b0000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390c000000000000000c0000000000000024ff807d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae390d000000000000000d0000000000000024ff808000000000000000";
        CommonTypes.InboundLaneData memory inboundLaneData2 = CommonTypes
            .decodeInboundLaneData(data2);
        assertEq(inboundLaneData2.relayers.length, 13);
        for (uint i = 0; i < inboundLaneData2.relayers.length; i++) {
            assertEq(
                inboundLaneData2.relayers[i].messages.dispatchResults.bits,
                9
            );
            assertEq(
                inboundLaneData2.relayers[i].relayer,
                0x7d8165c3628e175ccf2f3ffff318761fd9c04afe801dba109358acdf33fdae39
            );
        }
        assertEq(inboundLaneData2.lastConfirmedNonce, 128);
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
