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
    //             Transact: {
    //                 originType: SovereignAccount
    //                 requireWeightAtMost: 10000000
    //                 call: {
    //                     encoded: 0x260000400d03000000000000000000000000000000000000000000000000000000000001004617d470f847ce166019d19a7944049ebb01740000000000000000000000000000000000000000000000000000000000000000001019ff1d2100
    //                 }
    //             }
    //         }
    //     ]
    // }
    function testBuildForwardCall() public {
        bytes memory call = PalletMessageRouter.buildForwardCall(
            0x1a01,
            0, // Moonbeam
            hex"260000400d03000000000000000000000000000000000000000000000000000000000001004617d470f847ce166019d19a7944049ebb01740000000000000000000000000000000000000000000000000000000000000000001019ff1d2100",
            10000000
        );
        assertEq0(
            call,
            hex"1a010002040601025a62027d01260000400d03000000000000000000000000000000000000000000000000000000000001004617d470f847ce166019d19a7944049ebb01740000000000000000000000000000000000000000000000000000000000000000001019ff1d2100"
        );
    }
}
