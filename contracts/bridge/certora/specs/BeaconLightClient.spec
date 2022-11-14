// BeaconLightClient.spec

// Verify fallback always reverts
rule fallback_revert(method f) filtered { f -> f.isFallback } {
    env e;
    calldataarg arg;
    f@withrevert(e, arg);
    assert(lastReverted, "Fallback did not revert");
}

rule empty_finalized_header() {
    env e;
    uint64 slot;
    uint64 proposer_index;
    bytes32 parent_root;
    bytes32 state_root;
    bytes32 body_root;
    slot, proposer_index, parent_root, state_root, body_root = finalized_header(e);
    assert(slot == 0, "empty finalized header");
}
