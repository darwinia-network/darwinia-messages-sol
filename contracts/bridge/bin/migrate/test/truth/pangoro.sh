#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=pangolin
export TARGET_CHAIN=goerli
# export ETH_RPC_URL=https://pangoro-rpc.darwinia.network
export ETH_RPC_URL=http://34.142.158.86:8888

. $(dirname $0)/base.sh

load_saddr() {
  jq -r ".[\"$TARGET_CHAIN\"].\"$1\"" "$PWD/bin/addr/$MODE/$NETWORK_NAME.json"
}

load_taddr() {
  jq -r ".[\"$NETWORK_NAME\"].\"$1\"" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json"
}

# beacon light client config
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
SLOT=5101760
PROPOSER_INDEX=262949
PARENT_ROOT=0xeecc8ac3f7c20d755b9895d0adcf18bc767fce1926169841a3dd5d237347f8bb
STATE_ROOT=0xf7bcbde6217542b2ce6d14b3fecd2a39e03fbd16cf0b56716ca02c0c1ca270c5
BODY_ROOT=0x7e3bf9687187f50273643c0aa0153fe8747186ac5ec696e45e275768180153cf
CURRENT_SYNC_COMMITTEE_HASH=0x3e550c1ec5b6ce738f0f377dad7dabb3db732075bb2f716617bd2670326f51e2
GENESIS_VALIDATORS_ROOT=0x043db0d9a83813551ee2f33450d23797757d430911a9320530ad8a0eabc43efb

BeaconLightClient=$(deploy BeaconLightClient \
  $BLS_PRECOMPILE \
  $SLOT \
  $PROPOSER_INDEX \
  $PARENT_ROOT \
  $STATE_ROOT \
  $BODY_ROOT \
  $CURRENT_SYNC_COMMITTEE_HASH \
  $GENESIS_VALIDATORS_ROOT)

CAPELLA_FORK_EPOCH=162304
ExecutionLayer=$(deploy ExecutionLayer $BeaconLightClient $CAPELLA_FORK_EPOCH)

EthereumSerialLaneVerifier=$(load_saddr "EthereumSerialLaneVerifier")

seth send -F $ETH_FROM $EthereumSerialLaneVerifier "changeLightClient(address)" $ExecutionLayer
