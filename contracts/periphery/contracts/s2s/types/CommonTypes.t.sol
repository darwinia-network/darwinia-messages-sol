// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../ds-test/test.sol";
import "./CommonTypes.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract CommonTypesTest is DSTest {
    function setUp() public {}

    function testDecodeAndGetLastRelayer() public {
        bytes memory data = hex"0c12c21427b9698f161d479724581747426dff88f0309b07aaa5879d3ea1f22b390088526a740000000000000000000000ffc717a80400000000000000000000003664144d96d952303d2d401c936a1ef309b22be03207f19412ebb7f7faa0b1590048ca8e13000000000000000000000000c817a8040000000000000000000000f41d3260d736f5b3db8a6351766e97619ea35972546a5f850bbf0b27764abe0300d8c379580000000000000000000000003e3bad290000000000000000000000";
        CommonTypes.Relayer memory relayer = CommonTypes.decodeAndGetLastRelayer(data);
        assertTrue(relayer.fee == 179000000000);
    }
}