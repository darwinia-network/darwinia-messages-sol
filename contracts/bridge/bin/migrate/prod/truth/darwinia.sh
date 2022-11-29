#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=darwinia
export TARGET_CHAIN=ethlive
export ETH_RPC_URL=https://rpc.darwinia.network

echo "ETH_FROM: ${ETH_FROM}"

. $(dirname $0)/base.sh

load_saddr() {
  jq -r ".[\"$TARGET_CHAIN\"].\"$1\"" "$PWD/bin/addr/$MODE/$NETWORK_NAME.json"
}

load_taddr() {
  jq -r ".[\"$NETWORK_NAME\"].\"$1\"" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json"
}

# beacon light client config
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
SLOT=5225184
PROPOSER_INDEX=205286
PARENT_ROOT=0x278b67c45b0684beac03e61036011eb5c58460db0cd37d297507c5dc55bc57a9
STATE_ROOT=0x5a6c1264b2a98c8fb3012ad095f3dc745f4a55b71cf4b4101defd99c32373ac8
BODY_ROOT=0x08d9d0ff508a3ca59baf53b79af98f26fa531dec17b52086f59582feae0b9e76
CURRENT_SYNC_COMMITTEE_HASH=0xe81fbd2b71e6c8f7cd599fb7964a412bcdec3ebdd9843dc92b840c7663be89e8
GENESIS_VALIDATORS_ROOT=0x4b363db94e286120d76eb905340fdd4e54bfe9f06bf33ff6cf5ad27f511bfe95

BeaconLightClient=$(deploy BeaconLightClient \
  $BLS_PRECOMPILE \
  $SLOT \
  $PROPOSER_INDEX \
  $PARENT_ROOT \
  $STATE_ROOT \
  $BODY_ROOT \
  $CURRENT_SYNC_COMMITTEE_HASH \
  $GENESIS_VALIDATORS_ROOT)

ExecutionLayer=$(deploy ExecutionLayer $BeaconLightClient)
