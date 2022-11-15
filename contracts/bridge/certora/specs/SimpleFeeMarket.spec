// SimpleFeeMarket.spec

methods {
    setter()           returns address envfree
    outbounds(address) returns uint256    envfree
    balanceOf(address) returns uint256 envfree
    lockedOf(address)  returns uint256 envfree
    relayers(address)  returns address envfree
    relayerCount()     returns uint256 envfree
    feeOf(address)     returns uint256 envfree
    orderOf(uint256)   returns (uint32,address,uint256,uint256) envfree
}

// Verify fallback always reverts
rule fallback_revert(method f) filtered { f -> f.isFallback } {
    env e;
    calldataarg arg;
    f@withrevert(e, arg);
    assert(lastReverted, "Fallback did not revert");
}
