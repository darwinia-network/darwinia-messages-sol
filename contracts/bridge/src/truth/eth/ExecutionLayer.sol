// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../../spec/ChainMessagePosition.sol";
import "../common/StorageVerifier.sol";

interface IConsensusLayer {
    function verify_storage_proof(
        bytes32 leaf,
        bytes32[] calldata branch,
        uint64 depth,
        uint64 index
    ) external view returns (bool);
}

contract ExecutionLayer is StorageVerifier {
    event LatestExecutionPayloadStateRootImported(bytes32 state_root);

    address public immutable CONSENSUS_LAYER;

    uint64 constant private LATEST_EXECUTION_PAYLOAD_STATE_ROOT_INDEX = 898;
    uint64 constant private LATEST_EXECUTION_PAYLOAD_STATE_ROOT_DEPTH = 9;

    constructor(address consensus_layer) StorageVerifier(uint32(ChainMessagePosition.ETH), 0, 1, 2) {
        CONSENSUS_LAYER = consensus_layer;
    }

    struct ExecutionPayloadStateRootUpdate {
        // Execution payload state root in beacon state [New in Bellatrix]
        bytes32 latest_execution_payload_state_root;
        // Execution payload state root witnesses in beacon state
        bytes32[] latest_execution_payload_state_root_branch;
    }

    bytes32 private latest_execution_payload_state_root;

    function state_root() public view override returns (bytes32) {
        return latest_execution_payload_state_root;
    }

    function import_latest_execution_payload_state_root(ExecutionPayloadStateRootUpdate calldata update) external payable {
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
        return IConsensusLayer(CONSENSUS_LAYER).verify_storage_proof(
            execution_payload_state_root,
            execution_payload_state_root_branch,
            LATEST_EXECUTION_PAYLOAD_STATE_ROOT_DEPTH,
            LATEST_EXECUTION_PAYLOAD_STATE_ROOT_INDEX
        );
    }
}
