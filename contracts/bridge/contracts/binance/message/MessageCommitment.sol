// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../../interfaces/ILightClientBridge.sol";
import "./LaneDataScheme.sol";

contract MessageCommitment is LaneDataScheme {
    struct MessagesProof {
        Proof chainProof;
        Proof laneProof;
    }

    struct Proof {
        bytes32 root;
        uint256 count;
        bytes32[] proof;
    }

    /* State */
    /**
     * @dev The contract address of on-chain light client
     */
    ILightClientBridge public lightClientBridge;

    /**
     * @dev The position of the leaf in the `chain_message_merkle_tree`, index starting with 0
     */
    uint256 public chainPosition;

    /**
     * @dev The position of the leaf in the `lane_message_merkle_tree`, index starting with 0
     */
    uint256 public lanePosition;

    /**
     * @dev The lane data storage commitment
     */
    bytes32 public commitment;

    constructor(address _lightClientBridge, uint256 _chainPosition, uint256 _lanePosition) public {
        lightClientBridge = ILightClientBridge(_lightClientBridge);
        chainPosition = _chainPosition;
        lanePosition = _lanePosition;
    }

    /* Private Functions */

    function verify_messages_proof(
        bytes32 outboundLaneDataHash,
        bytes32 inboundLaneDataHash,
        MessagesProof memory messagesProof
    )
        internal
        view
    {
        // Validate that the commitment matches the commitment contents
        require(messagesProof.chainProof.root == lightClientBridge.getFinalizedChainMessagesRoot(), "Lane: invalid ChainMessagesRoot");
        require(
            validateMessagesMatchRoot(
                outboundLaneDataHash,
                inboundLaneDataHash,
                messagesProof.chainProof,
                messagesProof.laneProof
            ),
            "Lane: invalid messages"
        );
    }

    function validateMessagesMatchRoot(
        bytes32 outboundLaneDataHash,
        bytes32 inboundLaneDataHash,
        Proof memory chainProof,
        Proof memory laneProof
    ) internal view returns (bool) {
        bytes32 laneHash = hash(LaneData(outboundLaneDataHash, inboundLaneDataHash));
        return
            MerkleProof.verifyMerkleLeafAtPosition(
                laneProof.root,
                laneHash,
                lanePosition,
                laneProof.count,
                laneProof.proof
            )
            &&
            MerkleProof.verifyMerkleLeafAtPosition(
                chainProof.root,
                laneProof.root,
                chainPosition,
                chainProof.count,
                chainProof.proof
            );
    }

}

