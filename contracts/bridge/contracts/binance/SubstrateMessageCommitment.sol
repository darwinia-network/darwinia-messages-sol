// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../interfaces/ILightClientBridge.sol";

contract SubstrateMessageCommitment {
    struct LaneData {
        bytes32 outboundLaneDataHash;
        bytes32 inboundLaneDataHash;
    }

    /**
     * The BeefyMMRLeaf is the structure of each leaf in each MMR that each commitment's payload commits to.
     * @param parentHash parent hash of the block this leaf describes
     * @param chainMessagesRoot  chain message root is a two-level Merkle tree consisting of all messages from different chains and different lanes, chainMessagesRoot is the root hash of `chain_messages_merkle_tree`, and the leaves of `chain_messages_merkle_tree` are messages root of different chains, they form the first level of merkle tree, `lane_messages_root` is the root hash of `lane_messages_merkle_tree`, and the leaves of `lane_messages_merkle_tree` are the hashes of the message collections of different lanes, which form the second level of the merkle tree.
     * @param blockNumber block number for the block this leaf describes
     */
    struct BeefyMMRLeaf {
        bytes32 parentHash;
        bytes32 chainMessagesRoot;
        uint32 blockNumber;
    }

    /**
     * Hash of the LaneData Schema
     * keccak256(abi.encodePacked(
     *     "LaneData(bytes32 outboundLaneDataHash,bytes32 inboundLaneDataHash)"
     *     ")"
     * )
     */
    bytes32 internal constant LANEDATA_TYPEHASH = 0x8f6ab5f61c30d2037b3accf5c8898c9242d2acc51072316f994ac5d6748dd567;

    /**
     * Hash of the BeefyMMRLeaf Schema
     * keccak256(abi.encodePacked(
     *     "BeefyMMRLeaf(bytes32 parentHash,bytes32 chainMessagesRoot,uint32 blockNumber)"
     *     ")"
     * )
     */
    bytes32 internal constant BEEFYMMRLEAF_TYPEHASH = 0x344720a031552a825254ba106025d2909e0f38c0116c1aa520eed4e00ad8e215;



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

    /* Private Functions */

    function verifyMMRLeaf(
        BeefyMMRLeaf memory beefyMMRLeaf,
        uint256 beefyMMRLeafIndex,
        uint256 beefyMMRLeafCount,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) internal
      view
    {
        require(
            lightClientBridge.verifyBeefyMerkleLeaf(
                hash(beefyMMRLeaf),
                beefyMMRLeafIndex,
                beefyMMRLeafCount,
                peaks,
                siblings
            ),
            "Lane: Invalid proof"
        );
    }

    function verifyMessages(
        bytes32 outboundLaneDataHash,
        bytes32 inboundLaneDataHash,
        BeefyMMRLeaf memory leaf,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 laneMessagesRoot,
        uint256 laneCount,
        bytes32[] memory laneMessagesProof
    )
        internal
        view
    {
        require(
            leaf.blockNumber <= lightClientBridge.getFinalizedBlockNumber(),
            "Lane: block not finalized"
        );
        // Validate that the commitment matches the commitment contents
        require(
            validateMessagesMatchRoot(
                outboundLaneDataHash,
                inboundLaneDataHash,
                leaf.chainMessagesRoot,
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

    function hash(BeefyMMRLeaf memory leaf)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                abi.encodePacked(
                    BEEFYMMRLEAF_TYPEHASH,
                    leaf.parentHash,
                    leaf.chainMessagesRoot,
                    leaf.blockNumber
                )
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

