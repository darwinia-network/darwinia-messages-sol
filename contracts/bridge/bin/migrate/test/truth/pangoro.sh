#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=pangolin
export TARGET_CHAIN=goerli
export ETH_RPC_URL=https://pangolin-rpc.darwinia.network

. $(dirname $0)/base.sh

load_saddr() {
  jq -r ".[\"$TARGET_CHAIN\"].\"$1\"" "$PWD/bin/addr/$MODE/$NETWORK_NAME.json"
}

load_taddr() {
  jq -r ".[\"$NETWORK_NAME\"].\"$1\"" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json"
}

# beacon light client config
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
SLOT=5433408
PROPOSER_INDEX=338940
PARENT_ROOT=0xf7c0374ad89d9a28f6708bd7b02af59a7a2ed2463a4ef191aa55cdf6cf8001b2
STATE_ROOT=0x9840d388c38172332553e9445e7fd64185aba5212026d22dce5efccf41d5663d
BODY_ROOT=0x4b6cc5f729ae6a9d57f6b912d655467627ce4d057f10a1d0a8ad5f68c5c1a2e9
CURRENT_SYNC_COMMITTEE_HASH=0x4bcc8065b1462577a9971110aaa3ea5630ce3e6bc0ecb53e54777ce7d4a5e816
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

# EthereumSerialLaneVerifier=$(load_saddr "EthereumSerialLaneVerifier")
# seth send -F $ETH_FROM $EthereumSerialLaneVerifier "changeLightClient(address)" $BeaconLightClient
