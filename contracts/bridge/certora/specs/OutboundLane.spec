// OutboundLane.spec

methods {
    outboundLaneNonce() returns (uint64,uint64,uint64) envfree
    messages(uint64) returns bytes32 envfree
    commitment() returns bytes32 envfree
    message_size() returns uint64 envfree

    send_message(address,bytes) returns (uint64) => DISPATCHER(true)
}

// Verify fallback always reverts
rule fallback_revert(method f) filtered { f -> f.isFallback } {
    env e;
    calldataarg arg;
    f@withrevert(e, arg);
    assert(lastReverted, "Fallback did not revert");
}

rule send_message_noauth() {
    uint64 size0 = message_size();
    require(size0 == 0);
    env e;
    calldataarg arg;
    send_message(e, arg);
    uint64 size1 = message_size();
    assert(size1 == 1, "!send");
}
