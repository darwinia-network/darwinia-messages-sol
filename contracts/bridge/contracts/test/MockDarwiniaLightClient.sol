// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-verify/contracts/MerkleProof.sol";

contract MockDarwiniaLightClient {
    struct MessagesProof {
        MProof chainProof;
        MProof laneProof;
    }
    struct MProof {
        bytes32 root;
        uint256 count;
        bytes32[] proof;
    }

    bytes32 public latestChainMessagesRoot;

    function relayHeader(bytes32 message_root) public {
        latestChainMessagesRoot = message_root;
    }

    function verify_messages_proof(
        bytes32 outboundLaneDataHash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata proof
    ) external view returns (bool) {
        return validate_messages_match_root(outboundLaneDataHash, chain_pos, lane_pos, proof);
    }

    function verify_messages_delivery_proof(
        bytes32 inboundLaneDataHash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata proof
    ) external view returns (bool) {
        return validate_messages_match_root(inboundLaneDataHash, chain_pos, lane_pos, proof);
    }

    function validate_messages_match_root(
        bytes32 lane_hash,
        uint256 chain_pos,
        uint256 lane_pos,
        bytes memory proof
    ) internal view returns (bool) {
        MessagesProof memory messages_proof = abi.decode(proof, (MessagesProof));
        // Validate that the commitment matches the commitment contents
        require(messages_proof.chainProof.root == latestChainMessagesRoot, "Lane: invalid ChainMessagesRoot");
        return validateMessagesMatchRoot(
                lane_hash,
                chain_pos,
                lane_pos,
                messages_proof.chainProof,
                messages_proof.laneProof
            );
    }

    function validateMessagesMatchRoot(
        bytes32 laneHash,
        uint256 chainPosition,
        uint256 lanePosition,
        MProof memory chainProof,
        MProof memory laneProof
    ) internal pure returns (bool) {
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
