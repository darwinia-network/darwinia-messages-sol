// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

contract LightClientBSCMock {
    struct StorageProof {
        uint256 balance;
        bytes32 codeHash;
        uint256 nonce;
        bytes32 storageHash;
        bytes accountProof;
        bytes storageProof;
    }

    uint256 public immutable OUTBOUND_COMMITMENT_POSITION;
    uint256 public immutable INBOUND_COMMITMENT_POSITION;

    // bridgedChainPosition => lanePosition => bound
    mapping(uint256 => mapping(uint256 => address)) inbounds;
    mapping(uint256 => mapping(uint256 => address)) outbounds;

    constructor(uint256 outbound_commitment_position, uint256 inbound_commitment_position) public {
        OUTBOUND_COMMITMENT_POSITION = outbound_commitment_position;
        INBOUND_COMMITMENT_POSITION = inbound_commitment_position;
    }

    function verify_messages_proof(
        bytes32 outboundLaneDataHash,
        bytes32 /*inboundLaneDataHash*/,
        uint256 chain_pos,
        uint256 lane_pos,
        bytes calldata proof
    ) external view returns (bool) {
        StorageProof memory storage_proof = abi.decode(proof, (StorageProof));
        address outbound = outbounds[chain_pos][lane_pos];
        return verify_storage_proof(
            outboundLaneDataHash,
            outbound,
            OUTBOUND_COMMITMENT_POSITION,
            storage_proof
        );
    }

    function verify_messages_delivery_proof(
        bytes32 /*outboundLaneDataHash*/,
        bytes32 inboundLaneDataHash,
        uint256 chain_pos,
        uint256 lane_pos,
        bytes calldata proof
    ) external view returns (bool) {
        StorageProof memory storage_proof = abi.decode(proof, (StorageProof));
        address inbound = inbounds[chain_pos][lane_pos];
        return verify_storage_proof(
            inboundLaneDataHash,
            inbound,
            INBOUND_COMMITMENT_POSITION,
            storage_proof
        );
    }

    function verify_storage_proof(
        bytes32 /*commitment*/,
        address /*account*/,
        uint256 /*position*/,
        StorageProof memory /*proof*/
    ) internal pure returns (bool) {
        //TODO: do the storage_proof & account_proof
        return false;
    }
}
