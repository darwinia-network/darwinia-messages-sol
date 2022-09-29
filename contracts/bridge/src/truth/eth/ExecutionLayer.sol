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

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../spec/ChainMessagePosition.sol";
import "../../spec/MerkleProof.sol";
import "../../interfaces/ILightClient.sol";

interface IConsensusLayer {
    function state_root() external view returns (bytes32);
}

contract ExecutionLayer is MerkleProof, ILightClient {
    bytes32 private latest_execution_payload_state_root;

    address public immutable CONSENSUS_LAYER;

    uint64 constant private LATEST_EXECUTION_PAYLOAD_STATE_ROOT_INDEX = 898;
    uint64 constant private LATEST_EXECUTION_PAYLOAD_STATE_ROOT_DEPTH = 9;

    event LatestExecutionPayloadStateRootImported(bytes32 state_root);

    struct ExecutionPayloadStateRootUpdate {
        // Execution payload state root in beacon state [New in Bellatrix]
        bytes32 latest_execution_payload_state_root;
        // Execution payload state root witnesses in beacon state
        bytes32[] latest_execution_payload_state_root_branch;
    }

    constructor(address consensus_layer) {
        CONSENSUS_LAYER = consensus_layer;
    }

    function merkle_root() public view override returns (bytes32) {
        return latest_execution_payload_state_root;
    }

    function import_latest_execution_payload_state_root(ExecutionPayloadStateRootUpdate calldata update) external {
        require(latest_execution_payload_state_root != update.latest_execution_payload_state_root, "same");
        require(verify_latest_execution_payload_state_root(
            update.latest_execution_payload_state_root,
            update.latest_execution_payload_state_root_branch),
           "!execution_payload_state_root"
        );
        latest_execution_payload_state_root = update.latest_execution_payload_state_root;
        emit LatestExecutionPayloadStateRootImported(update.latest_execution_payload_state_root);
    }

    function verify_latest_execution_payload_state_root(
        bytes32 execution_payload_state_root,
        bytes32[] calldata execution_payload_state_root_branch
    ) internal view returns (bool) {
        require(execution_payload_state_root_branch.length == LATEST_EXECUTION_PAYLOAD_STATE_ROOT_DEPTH, "!execution_payload_state_root_branch");
        return is_valid_merkle_branch(
            execution_payload_state_root,
            execution_payload_state_root_branch,
            LATEST_EXECUTION_PAYLOAD_STATE_ROOT_DEPTH,
            LATEST_EXECUTION_PAYLOAD_STATE_ROOT_INDEX,
            IConsensusLayer(CONSENSUS_LAYER).state_root()
        );
    }
}
