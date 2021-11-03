// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../interfaces/ILightClientBridge.sol";

contract MessageCommitment {
    struct LaneData {
        bytes32 outboundLaneDataHash;
        bytes32 inboundLaneDataHash;
    }

    /**
     * Hash of the LaneData Schema
     * keccak256(abi.encodePacked(
     *     "LaneData(bytes32 outboundLaneDataHash,bytes32 inboundLaneDataHash)"
     *     ")"
     * )
     */
    bytes32 internal constant LANEDATA_TYPEHASH = 0x8f6ab5f61c30d2037b3accf5c8898c9242d2acc51072316f994ac5d6748dd567;


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
     * @dev The position of the leaf in the `lane_messages_merkle_tree`, index starting with 0
     */
    uint256 public lanePosition;

    constructor(address _lightClientBridge, uint256 _chainPosition, uint256 _lanePosition) public {
        lightClientBridge = ILightClientBridge(_lightClientBridge);
        chainPosition = _chainPosition;
        lanePosition = _lanePosition;
    }

    /* Private Functions */

    function verify_messages_proof(
        bytes32 outboundLaneDataHash,
        bytes32 inboundLaneDataHash,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 laneMessagesRoot,
        uint256 laneCount,
        bytes32[] memory laneMessagesProof
    )
        internal
        view
    {
        // Validate that the commitment matches the commitment contents
        require(
            validateMessagesMatchRoot(
                outboundLaneDataHash,
                inboundLaneDataHash,
                lightClientBridge.getFinalizedChainMessagesRoot(),
                chainCount,
                chainMessagesProof,
                laneMessagesRoot,
                laneCount,
                laneMessagesProof
            ),
            "Lane: invalid messages"
        );
    }

    function validateMessagesMatchRoot(
        bytes32 outboundLaneDataHash,
        bytes32 inboundLaneDataHash,
        bytes32 chainMessagesRoot,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 laneMessagesRoot,
        uint256 laneCount,
        bytes32[] memory laneMessagesProof
    ) internal view returns (bool) {
        bytes32 laneHash = hash(LaneData(outboundLaneDataHash, inboundLaneDataHash));
        return
            MerkleProof.verifyMerkleLeafAtPosition(
                laneMessagesRoot,
                laneHash,
                lanePosition,
                laneCount,
                laneMessagesProof
            )
            &&
            MerkleProof.verifyMerkleLeafAtPosition(
                chainMessagesRoot,
                laneMessagesRoot,
                chainPosition,
                chainCount,
                chainMessagesProof
            );
    }

    function hash(LaneData memory land_data)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                LANEDATA_TYPEHASH,
                land_data.outboundLaneDataHash,
                land_data.inboundLaneDataHash
            )
        );
    }
}

