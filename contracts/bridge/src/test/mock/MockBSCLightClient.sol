// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;
pragma abicoder v2;

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
    mapping(uint32 => mapping(uint32 => address)) public lanes;
    bytes32 public stateRoot;

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
