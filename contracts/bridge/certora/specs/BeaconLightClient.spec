// BeaconLightClient.spec

methods {
    finalized_header() returns (uint64,uint64,bytes32,bytes32,bytes32) envfree
    sync_committee_roots(uint64) returns bytes32 envfree

//    call_ip_next_sync_committee()
    call_ip_finalized_header()
}

definition SLOTS_PER_EPOCH() returns uint64 = 32;
definition EPOCHS_PER_SYNC_COMMITTEE_PERIOD() returns uint64 = 256;

function get_finalized_header_slot() returns uint64 {
    uint64 slot;
    uint64 proposer_index;
    bytes32 parent_root;
    bytes32 state_root;
    bytes32 body_root;
    slot, proposer_index, parent_root, state_root, body_root = finalized_header();
    return slot;
}

// Verify fallback always reverts
rule fallback_revert(method f) filtered { f -> f.isFallback } {
    env e;
    calldataarg arg;
    f@withrevert(e, arg);
    assert(lastReverted, "Fallback did not revert");
}

rule ip_finalized_header() {
    uint64 slot0 = get_finalized_header_slot();

    env e;
    call_ip_finalized_header(e);

    uint64 slot1 = get_finalized_header_slot();
    assert(slot1 > slot0, "import new block header");
}

// rule ip_next_sync_committee() {
//     uint64 slot0 = get_finalized_header_slot();
//     uint64 period0 = slot0 / SLOTS_PER_EPOCH() / EPOCHS_PER_SYNC_COMMITTEE_PERIOD();
//     bytes32 root0 = sync_committee_roots(period0);

//     env e;
//     call_ip_next_sync_committee(e);

//     uint64 period1 = period0 + 1;
//     bytes32 root1 = sync_committee_roots(period1);

//     uint64 slot1 = get_finalized_header_slot();
//     assert(slot1 >= slot0, "import new block header or not");
//     bytes32 zero = 0x0000000000000000000000000000000000000000000000000000000000000000;
//     assert(root0 != zero && root1 == zero => (root1 != zero), "import new synccommittee");
// }
