// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../../lib/ds-test/src/test.sol";
import "../../../truth/darwinia/DarwiniaLightClient.sol";

contract DarwiniaLightClientTest is DSTest {
    // bytes32 constant internal NETWORK = 0x50616e676f6c696e000000000000000000000000000000000000000000000000;
    // address constant internal BEEFY_SLASH_VALUT = 0x0000000000000000000000000000000000000000;
    // uint64  constant internal BEEFY_VALIDATOR_SET_ID = 0;
    // uint32  constant internal BEEFY_VALIDATOR_SET_LEN = 4;
    // bytes32 constant internal BEEFY_VALIDATOR_SET_ROOT = 0xa1ce8df8151796ab60157e0c6075a3a4cc170927b1b1fc0f33bde0e274e8f398;

     function get_power_of_two_ceil(uint256 x) internal pure returns (uint256) {
         if (x <= 1) return 1;
         else if (x == 2) return 2;
         else return 2 * get_power_of_two_ceil((x + 1) / 2);
     }

    // function setUp() public {
    //     lightclient = new DarwiniaLightClient(
    //         NETWORK
    //         BEEFY_SLASH_VALUT,
    //         BEEFY_VALIDATOR_SET_ID,
    //         BEEFY_VALIDATOR_SET_LEN,
    //         BEEFY_VALIDATOR_SET_ROOT
    //     );
    //     self = address(this);
    // }

    function test_round_up_to_pow2() public {
        assertEq(get_power_of_two_ceil(100), 128);
    }
}
