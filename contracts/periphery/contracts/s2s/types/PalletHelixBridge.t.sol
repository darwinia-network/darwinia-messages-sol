// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../ds-test/test.sol";
import "./PalletHelixBridge.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract PalletHelixBridgeTest is DSTest {
    function setUp() public {}

    function testEncodeIssueFromRemoteCall() public {
        PalletHelixBridge.IssueFromRemoteCall memory call = PalletHelixBridge.IssueFromRemoteCall(
            0x1800,
            12345,
            0x90b5ab205c6974c9ea841be688864633dc9ca8a357843eeacf2314649965fe22,
            new uint64[](2),
            23
        );
        call.burnPrunedMessages[0] = 0;
        call.burnPrunedMessages[1] = 2;
        bytes memory expect = hex"18003930000000000000000000000000000090b5ab205c6974c9ea841be688864633dc9ca8a357843eeacf2314649965fe2208000000000000000002000000000000001700000000000000";
        bytes memory result = PalletHelixBridge.encodeIssueFromRemoteCall(call);
        assertEq0(result, expect);
    }

    function testEncodeIssueFromRemoteCall2() public {
        PalletHelixBridge.IssueFromRemoteCall memory call = PalletHelixBridge.IssueFromRemoteCall(
            0x1800,
            0,
            0x90b5ab205c6974c9ea841be688864633dc9ca8a357843eeacf2314649965fe22,
            new uint64[](0),
            0
        );
        bytes memory expect = hex"18000000000000000000000000000000000090b5ab205c6974c9ea841be688864633dc9ca8a357843eeacf2314649965fe22000000000000000000";
        bytes memory result = PalletHelixBridge.encodeIssueFromRemoteCall(call);
        assertEq0(result, expect);
    }

    function testEncodeHandleIssuingFailureFromRemoteCall() public {
        PalletHelixBridge.HandleIssuingFailureFromRemoteCall memory call = PalletHelixBridge.HandleIssuingFailureFromRemoteCall(
            0x1802,
            12345,
            new uint64[](2),
            23
        );
        call.burnPrunedMessages[0] = 0;
        call.burnPrunedMessages[1] = 2;
        bytes memory expect = hex"1802393000000000000008000000000000000002000000000000001700000000000000";
        bytes memory result = PalletHelixBridge.encodeHandleIssuingFailureFromRemoteCall(call);
        assertEq0(result, expect);
    }
}
