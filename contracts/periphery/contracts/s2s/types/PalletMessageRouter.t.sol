// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../ds-test/test.sol";
import "./PalletMessageRouter.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract PalletMessageRouterTest is DSTest {
    function setUp() public {}

    // {
    //     V2: [
    //         {
    //         DescendOrigin: {
    //             X1: {
    //             AccountKey20: {
    //                 network: {
    //                 Named: CrabSmartChain
    //                 }
    //                 key: 0xf24FF3a9CF04c71Dbc94D0b566f7A27B94566cac
    //             }
    //             }
    //         }
    //         }
    //         {
    //         Transact: {
    //             originType: SovereignAccount
    //             requireWeightAtMost: 5,000,000,000
    //             call: {
    //             encoded: 0x260000400d03000000000000000000000000000000000000000000000000000000000001004617d470f847ce166019d19a7944049ebb01740000000000000000000000000000000000000000000000000000000000000000001019ff1d2100
    //             }
    //         }
    //         }
    //     ]
    // }
    // callIndex	1a01
    // message	02 08
    // 0b 01 03
    // network	01 38 43726162536d617274436861696e
    // key	f24FF3a9CF04c71Dbc94D0b566f7A27B94566cac
    // 06
    // originType	01
    // requireWeightAtMost	0700f2052a01
    // encoded	7d01 260000400d03000000000000000000000000000000000000000000000000000000000001004617d470f847ce166019d19a7944049ebb01740000000000000000000000000000000000000000000000000000000000000000001019ff1d2100
    function testEncodeVersionedXcmV2() public {
        bytes memory call = PalletMessageRouter.buildForwardToMoonbeamCall(
            0x1a01,
            hex"43726162536d617274436861696e",
            0xf24FF3a9CF04c71Dbc94D0b566f7A27B94566cac,
            hex"260000400d03000000000000000000000000000000000000000000000000000000000001004617d470f847ce166019d19a7944049ebb01740000000000000000000000000000000000000000000000000000000000000000001019ff1d2100"
        );
        assertEq0(
            call,
            hex"1a0102080b0103013843726162536d617274436861696ef24FF3a9CF04c71Dbc94D0b566f7A27B94566cac06010700f2052a017d01260000400d03000000000000000000000000000000000000000000000000000000000001004617d470f847ce166019d19a7944049ebb01740000000000000000000000000000000000000000000000000000000000000000001019ff1d2100"
        );
    }
}
