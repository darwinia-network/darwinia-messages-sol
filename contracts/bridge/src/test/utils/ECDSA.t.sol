// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../lib/ds-test/src/test.sol";
import "../../common/utils/ECDSA.sol";

contract ECDSATest is DSTest {
    function test_recover() public {
        bytes memory encodedCommitment = hex"0464628030a08a844614bf3503bfb134923ce2a21a43dd73052253d8879ccbe764b0e7a0490100000000000000000000";
        bytes memory signature = hex"f66eb23493e1dc95edf1e52f48372631ce9e59776501bbd393c6a9eba2a0baf8368645c79b813219862fffee6786dbbc299985c9cb6525cc89cf6959630f3b1c1b";
        address addr = 0x5630a480727CD7799073b36472d9b1A6031F840b;
        bytes32 hash = keccak256(encodedCommitment);
        assertEq(ECDSA.recover(hash, signature), addr);
    }

    function testFail_recover() public {
        bytes memory encodedCommitment = hex"0464628030a08a844614bf3503bfb134923ce2a21a43dd73052253d8879ccbe764b0e7a0490100000000000000000000";
        bytes memory signature = hex"f66eb23493e1dc95edf1e52f48372631ce9e59776501bbd393c6a9eba2a0baf8368645c79b813219862fffee6786dbbc299985c9cb6525cc89cf6959630f3b1c01";
        address addr = 0x5630a480727CD7799073b36472d9b1A6031F840b;
        bytes32 hash = keccak256(encodedCommitment);
        assertEq(ECDSA.recover(hash, signature), addr);
    }
}
