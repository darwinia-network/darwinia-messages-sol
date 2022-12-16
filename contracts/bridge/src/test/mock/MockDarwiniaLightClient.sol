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

import "../../utils/smt/SparseMerkleProof.sol";

contract MockDarwiniaLightClient {
    struct MessagesProof {
        MProof chainProof;
        MProof laneProof;
    }
    struct MProof {
        bytes32 root;
        bytes32[] proof;
    }

    bytes32 public latestChainMessagesRoot;

    function relayHeader(bytes32 message_root) public {
        latestChainMessagesRoot = message_root;
    }

    function verify_messages_proof(
        bytes32 outlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool) {
        return validate_lane_data_match_root(outlane_data_hash, chain_pos, lane_pos, encoded_proof);
    }

    function verify_messages_delivery_proof(
        bytes32 inlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool) {
        return validate_lane_data_match_root(inlane_data_hash, chain_pos, lane_pos, encoded_proof);
    }

    function validate_lane_data_match_root(
        bytes32 lane_hash,
        uint256 chain_pos,
        uint256 lane_pos,
        bytes memory proof
    ) internal view returns (bool) {
        MessagesProof memory messages_proof = abi.decode(proof, (MessagesProof));
        // Validate that the commitment matches the commitment contents
        require(messages_proof.chainProof.root == latestChainMessagesRoot, "Lane: invalid ChainMessagesRoot");
        return validateLaneDataMatchRoot(
                lane_hash,
                chain_pos,
                lane_pos,
                messages_proof.chainProof,
                messages_proof.laneProof
            );
    }

    function validateLaneDataMatchRoot(
        bytes32 laneHash,
        uint256 chainPosition,
        uint256 lanePosition,
        MProof memory chainProof,
        MProof memory laneProof
    ) internal pure returns (bool) {
        return
            SparseMerkleProof.singleVerify(
                laneProof.root,
                laneHash,
                lanePosition,
                laneProof.proof
            )
            &&
            SparseMerkleProof.singleVerify(
                chainProof.root,
                laneProof.root,
                chainPosition,
                chainProof.proof
            );
    }
}
