// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../../interfaces/ILightClient.sol";

contract MessageVerifier {
    /**
     * @dev This chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
     */
    uint32 public immutable thisChainPosition;

    /**
     * @dev This lane position of the leaf in the `lane_message_merkle_tree`, index starting with 0
     */
    uint32 public immutable thisLanePosition;

    /**
     * @dev Bridged chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
     */
    uint32 public immutable bridgedChainPosition;

    /**
     * @dev bridged lane position of the leaf in the `lane_message_merkle_tree`, index starting with 0
     */
    uint32 public immutable bridgedLanePosition;

    /* State */
    /**
     * @dev The contract address of on-chain light client
     */
    ILightClient public lightClient;

    /**
     * @dev The lane data storage commitment
     */
    bytes32 public commitment;

    constructor(
        address _lightClient,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) public {
        lightClient = ILightClient(_lightClient);
        thisChainPosition = _thisChainPosition;
        thisLanePosition = _thisLanePosition;
        bridgedChainPosition = _bridgedChainPosition;
        bridgedLanePosition = _bridgedLanePosition;
    }

    /* Private Functions */

    function verify_lane_data_proof(
        bytes32 outboundLaneDataHash,
        bytes memory messagesProof
    ) internal view {
        require(
            lightClient.verify_lane_data_proof(outboundLaneDataHash, thisChainPosition, bridgedLanePosition, messagesProof),
            "Verifer: InvalidProof"
        );
    }
}

