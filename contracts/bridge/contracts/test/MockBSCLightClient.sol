// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

// import "hardhat/console.sol";

contract MockBSCLightClient {
    struct StorageProof {
        uint256 balance;
        bytes32 codeHash;
        uint256 nonce;
        bytes32 storageHash;
        bytes accountProof;
        bytes storageProof;
    }

    uint256 public immutable LANE_COMMITMENT_POSITION;

    // bridgedChainPosition => lanePosition => lanes
    mapping(uint32 => mapping(uint32 => address)) lanes;
    bytes32 stateRoot;

    constructor(uint32 lane_commitment_position) {
        LANE_COMMITMENT_POSITION = lane_commitment_position;
    }

    function setBound(uint32 bridgedChainPosition, uint32 outboundPosition, address outbound, uint32 inboundPositon, address inbound) public {
        lanes[bridgedChainPosition][outboundPosition] = outbound;
        lanes[bridgedChainPosition][inboundPositon] = inbound;
    }

    function relayHeader(bytes32 _stateRoot) public {
        stateRoot = _stateRoot;
    }

    function verify_messages_proof(
        bytes32,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata
    ) external view returns (bool) {
        // StorageProof memory storage_proof = abi.decode(proof, (StorageProof));
        address lane = lanes[chain_pos][lane_pos];
        require(lane != address(0), "missing: lane addr");
        // console.log(lane);
        return true;
        // return verify_storage_proof(
        //     lane_hash,
        //     lane,
        //     LANE_COMMITMENT_POSITION,
        //     storage_proof
        // );
    }

    function verify_messages_delivery_proof(
        bytes32,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata
    ) external view returns (bool) {
        // StorageProof memory storage_proof = abi.decode(proof, (StorageProof));
        address lane = lanes[chain_pos][lane_pos];
        require(lane != address(0), "missing: lane addr");
        // console.log(lane);
        return true;
        // return verify_storage_proof(
        //     lane_hash,
        //     lane,
        //     LANE_COMMITMENT_POSITION,
        //     storage_proof
        // );
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
