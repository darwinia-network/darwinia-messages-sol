// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../../interfaces/ILightClient.sol";

contract MessageVerifier {
    /**
     * @dev The this chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
     */
    uint256 public immutable thisChainPosition;

    /**
     * @dev The bridged chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
     */
    uint256 public immutable bridgedChainPosition;

    /**
     * @dev The position of the leaf in the `lane_message_merkle_tree`, index starting with 0
     */
    uint256 public immutable lanePosition;

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
        uint256 _thisChainPosition,
        uint256 _bridgedChainPosition,
        uint256 _lanePosition
    ) public {
        lightClient = ILightClient(_lightClient);
        thisChainPosition = _thisChainPosition;
        bridgedChainPosition = _bridgedChainPosition;
        lanePosition = _lanePosition;
    }

    /* Private Functions */

    function verify_messages_proof(
        bytes32 outboundLaneDataHash,
        bytes32 inboundLaneDataHash,
        bytes memory messagesProof
    ) internal view {
        require(
            lightClient.verify_messages_proof(outboundLaneDataHash, inboundLaneDataHash, thisChainPosition, lanePosition, messagesProof),
            "Lane: invalid proof"
        );
    }

    function verify_messages_delivery_proof(
        bytes32 outboundLaneDataHash,
        bytes32 inboundLaneDataHash,
        bytes memory messagesProof
    ) internal view {
        require(
            lightClient.verify_messages_delivery_proof(outboundLaneDataHash, inboundLaneDataHash, thisChainPosition, lanePosition, messagesProof),
            "Lane: invalid delivery proof"
        );
    }
}

