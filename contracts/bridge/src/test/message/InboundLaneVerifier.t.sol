// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import "../test.sol";
import "../../message/InboundLaneVerifier.sol";
import "../mock/MockLightClient.sol";

contract InboundLaneVerifierTest is DSTest {
    uint32 constant internal THIS_CHAIN_POS = 0;
    uint32 constant internal THIS_IN_LANE_POS = 1;
    uint32 constant internal BRIDGED_CHAIN_POS = 1;
    uint32 constant internal BRIDGED_OUT_LANE_POS = 0;

    MockLightClient public lightclient;
    InboundLaneVerifier public verifier;

    function setUp() public {
        lightclient = new MockLightClient();
        verifier = new InboundLaneVerifier(
            address(lightclient),
            THIS_CHAIN_POS,
            THIS_IN_LANE_POS,
            BRIDGED_CHAIN_POS,
            BRIDGED_OUT_LANE_POS
        );
    }

    function test_contructor_args() public {
        assertEq(verifier.bridgedLanePosition(), uint(BRIDGED_OUT_LANE_POS));
        assertEq(verifier.bridgedChainPosition(), uint(BRIDGED_CHAIN_POS));
        assertEq(verifier.thisLanePosition(), uint(THIS_IN_LANE_POS));
        assertEq(verifier.thisChainPosition(), uint(THIS_CHAIN_POS));

        (uint32 thisChainPosition,uint32 thisLanePosition,uint32 bridgedChainPosition,uint32 bridgedLanePosition) = verifier.getLaneInfo();
        assertEq(thisChainPosition, uint(THIS_CHAIN_POS));
        assertEq(thisLanePosition, uint(THIS_IN_LANE_POS));
        assertEq(bridgedChainPosition, uint(BRIDGED_CHAIN_POS));
        assertEq(bridgedLanePosition, uint(BRIDGED_OUT_LANE_POS));
    }

    function test_encode_message_key() public {
        assertEq(verifier.encodeMessageKey(1), uint256(0x0000000000000000000000010000000000000000000000010000000000000001));
    }
}
