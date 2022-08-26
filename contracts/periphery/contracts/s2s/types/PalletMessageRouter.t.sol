// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../ds-test/test.sol";
import "./PalletMessageRouter.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract PalletMessageRouterTest is DSTest {
    function setUp() public {}

    // message	            02 04
    //                      06
    // originType	        00
    // requireWeightAtMost	30
    // encoded call         08 1234
    function testEncodeVersionedXcmV2() public {
        // build transacts
        PalletMessageRouter.Transact[]
            memory transacts = new PalletMessageRouter.Transact[](1);
        transacts[0] = PalletMessageRouter.Transact(0, 12, hex"1234");
        PalletMessageRouter.VersionedXcmV2WithTransacts
            memory message = PalletMessageRouter.VersionedXcmV2WithTransacts(
                transacts
            );

        // encode VersionedXcm
        bytes memory data = PalletMessageRouter
            .encodeVersionedXcmV2WithTransacts(message);

        assertEq0(data, hex"0204060030081234");
    }
}
