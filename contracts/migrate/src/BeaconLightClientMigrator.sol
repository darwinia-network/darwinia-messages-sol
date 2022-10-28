pragma solidity 0.7.6;
pragma abicoder v2;

import "BeaconLightClient.sol";
import "EthereumStorageVerifier.sol";
import "ExecutionLayer.sol";

contract BeaconLightClientMigrator {
    BeaconLightClient public new_beacon_lc;
    ExecutionLayer public new_execution_layer;

    address public immutable OLD_BEACON_LC;
    address public immutable ETHEREUM_STORAGE_VERIFIER;
    address public immutable BLS_PRECOMPILE;
    bytes32 public immutable GENESIS_VALIDATORS_ROOT;

    contructor(
        address old_lc,
        address verifier,
        address bls,
        bytes32 genesis_validators_root
    ) {
        OLD_BEACON_LC = old_lc;
        ETHEREUM_STORAGE_VERIFIER = verifier;
        BLS_PRECOMPILE = bls;
        GENESIS_VALIDATORS_ROOT = genesis_validators_root;
    }

    function migrate() public {
        // fetch latest finalized header
        BeaconLightClient.BeaconBlockHeader memory header = BeaconLightClient(OLD_BEACON_LC).finalized_header();
        // current sync committee period
        uint64 period = header.slot / 32 / 256;
        // fetch current sync_committee hash
        bytes32 current_sync_committee_hash = BeaconLightClient(OLD_BEACON_LC).sync_committee_roots(period);
        require(current_sync_committee_hash != bytes32(0), "missing");

        // new BeaconLightClient
        new_beacon_lc = new BeaconLightClient(
            BLS_PRECOMPILE,
            header.slot,
            header.proposer_index,
            header.parent_root,
            header.state_root,
            header.body_root,
            current_sync_committee_hash,
            GENESIS_VALIDATORS_ROOT
        );
        // new ExecutionLayer
        new_execution_layer = new ExecutionLayer(new_beacon_lc);
        // change light client
        EthereumStorageVerifier(EthereumStorageVerifier).changeLightClient(new_execution_layer);
    }
}
