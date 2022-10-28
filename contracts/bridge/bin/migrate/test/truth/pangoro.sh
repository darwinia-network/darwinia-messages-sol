#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=pangoro
export TARGET_CHAIN=goerli
# export ETH_RPC_URL=https://pangoro-rpc.darwinia.network
export ETH_RPC_URL=http://35.247.165.91:9933

. $(dirname $0)/base.sh

load_saddr() {
  jq -r ".[\"$TARGET_CHAIN\"].\"$1\"" "$PWD/bin/addr/$MODE/$NETWORK_NAME.json"
}

load_taddr() {
  jq -r ".[\"$NETWORK_NAME\"].\"$1\"" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json"
}

# beacon light client config
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
SLOT=4058368
PROPOSER_INDEX=1438
PARENT_ROOT=0x0bc723434538646fa17c2007c7084ae87b5ab3fe42592a7410e625ac637f0650
STATE_ROOT=0x7f357270e0f5fb4fe24d95ab25b7f236e0a63d6e1de344c0cbbc467473ce9b39
BODY_ROOT=0x71f3029440652538f098eaeae1e605943537486a673dc37073691446c19ac8a8
CURRENT_SYNC_COMMITTEE_HASH=0x2566080db27d495cd2e5268b08fb6995019276e10014ffdc5d1dff68cccdf47e
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

ExecutionLayer=$(deploy ExecutionLayer $BeaconLightClient)

# EthereumStorageVerifier=$(load_saddr "EthereumStorageVerifier")

# seth send -F $ETH_FROM $EthereumStorageVerifier "changeLightClient(address)" $ExecutionLayer
