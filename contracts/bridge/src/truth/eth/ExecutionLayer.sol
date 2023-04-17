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

import "../../spec/ChainMessagePosition.sol";
import "../../spec/BeaconChain.sol";
import "../../interfaces/ILightClient.sol";

interface IConsensusLayer {
    function body_root() external view returns (bytes32);
}

contract ExecutionLayer is BeaconChain, ILightClient {
    /// @dev latest execution payload's state root of beacon chain state root
    bytes32 private state_root;
    /// @dev latest execution payload's block number of beacon chain state root
    uint256 public block_number;
    /// @dev consensus layer
    address public immutable CONSENSUS_LAYER;

    uint64 constant private EXECUTION_PAYLOAD_INDEX = 25;
    uint64 constant private EXECUTION_PAYLOAD_DEPTH = 4;

    event LatestStateRootImported(uint256 block_number, bytes32 state_root);

    constructor(address consensus_layer) {
        CONSENSUS_LAYER = consensus_layer;
    }

    /// @dev Return latest execution payload state root
    /// @return merkle root
    function merkle_root() public view override returns (bytes32) {
        return state_root;
    }

    /// @dev follow beacon api: /eth/v2/beacon/blocks/{block_id}
    function import_state_root(ExecutionPayloadHeaderCapella calldata header, bytes32[] calldata execution_branch) external {
        bytes32 state_root_ = header.state_root;
        uint256 block_number_ = header.block_number;
        require(block_number_ > block_number, "!new");

        require(execution_branch.length == EXECUTION_PAYLOAD_DEPTH, "!execution_branch");
        require(is_valid_merkle_branch(
            hash_tree_root(header),
            execution_branch,
            EXECUTION_PAYLOAD_DEPTH,
            EXECUTION_PAYLOAD_INDEX,
            IConsensusLayer(CONSENSUS_LAYER).body_root()),
            "!execution_payload_header"
       );

        state_root = state_root_;
        block_number = block_number_;
        emit LatestStateRootImported(block_number_, state_root_);
    }
}
