// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../../interfaces/ILightClient.sol";

contract MessageVerifier {
    /**
     * @dev The this chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
     */
    uint32 public immutable thisChainPosition;

    /**
     * @dev The bridged chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
     */
    uint32 public immutable bridgedChainPosition;

    /**
     * @dev The position of the leaf in the `lane_message_merkle_tree`, index starting with 0
     */
    uint32 public immutable lanePosition;

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
        uint32 _bridgedChainPosition,
        uint32 _lanePosition
    ) public {
        lightClient = ILightClient(_lightClient);
        require(_thisChainPosition <= uint64(-1) && _bridgedChainPosition <= uint64(-1) && _lanePosition <= uint64(-1), "Verifer: Overflow");
        thisChainPosition = _thisChainPosition;
        bridgedChainPosition = _bridgedChainPosition;
        lanePosition = _lanePosition;
    }

    /* Private Functions */

    function verify_messages_proof(
        bytes32 outboundLaneDataHash,
        bytes memory messagesProof
    ) internal view {
        require(
            lightClient.verify_messages_proof(outboundLaneDataHash, thisChainPosition, lanePosition, messagesProof),
            "Verifer: InvalidProof"
        );
    }

    function verify_messages_delivery_proof(
        bytes32 outboundLaneDataHash,
        bytes memory messagesProof
    ) internal view {
        require(
            lightClient.verify_messages_delivery_proof(outboundLaneDataHash, thisChainPosition, lanePosition, messagesProof),
            "Verifer: InvalidDeliveryProof"
        );
    }
}

