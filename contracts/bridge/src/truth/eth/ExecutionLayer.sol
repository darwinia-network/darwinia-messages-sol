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
import "../../spec/BeaconChain.sol";
import "../../interfaces/ILightClient.sol";

interface IConsensusLayer {
    function body_root() external view returns (bytes32);
}

contract ExecutionLayer is BeaconChain, ILightClient {
    bytes32 private latest_execution_payload_state_root;

    address public immutable CONSENSUS_LAYER;

    event LatestExecutionPayloadStateRootImported(bytes32 state_root);

    constructor(address consensus_layer) {
        CONSENSUS_LAYER = consensus_layer;
    }

    function merkle_root() public view override returns (bytes32) {
        return latest_execution_payload_state_root;
    }

    // follow beacon api: /eth/v2/beacon/blocks/{block_id}
    function import_latest_execution_payload_state_root(BeaconBlockBody calldata body) external {
        bytes32 state_root = body.execution_payload.state_root;
        require(latest_execution_payload_state_root != state_root, "same");
        require(hash_tree_root(body) == IConsensusLayer(CONSENSUS_LAYER).body_root(), "!body");
        latest_execution_payload_state_root = state_root;
        emit LatestExecutionPayloadStateRootImported(state_root);
    }
}
