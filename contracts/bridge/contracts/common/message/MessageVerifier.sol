// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../../interfaces/ILightClientBridge.sol";
import "./LaneDataScheme.sol";

contract MessageVerifier is LaneDataScheme {

    /* State */
    /**
     * @dev The contract address of on-chain light client
     */
    ILightClientBridge public lightClientBridge;

    /**
     * @dev The this chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
     */
    uint256 public thisChainPosition;

    /**
     * @dev The bridged chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
     */
    uint256 public bridgedChainPosition;

    /**
     * @dev The position of the leaf in the `lane_message_merkle_tree`, index starting with 0
     */
    uint256 public lanePosition;

    /**
     * @dev The lane data storage commitment
     */
    bytes32 public commitment;

    constructor(
        address _lightClientBridge,
        uint256 _thisChainPosition,
        uint256 _bridgedChainPosition,
        uint256 _lanePosition
    ) public {
        lightClientBridge = ILightClientBridge(_lightClientBridge);
        thisChainPosition = _thisChainPosition;
        bridgedChainPosition = _bridgedChainPosition;
        lanePosition = _lanePosition;
    }

    /* Private Functions */

    function verify_messages_proof(
        bytes32 outboundLaneDataHash,
        bytes32 inboundLaneDataHash,
        bytes memory messagesProof
    )
        internal
        view
    {
        bytes32 lane_hash = hash(LaneData(outboundLaneDataHash, inboundLaneDataHash));
        require(lightClientBridge.validate_messages_match_root(lane_hash, thisChainPosition, lanePosition, messagesProof), "Lane: invalid proof");
    }
}

