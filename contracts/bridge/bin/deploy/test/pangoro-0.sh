#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=pangoro
# export ETH_RPC_URL=https://pangoro-rpc.darwinia.network
export ETH_RPC_URL=http://35.247.165.91:9933

echo "ETH_FROM: ${ETH_FROM}"

# import the deployment helpers
. $(dirname $0)/common.sh

BridgeProxyAdmin=$(deploy BridgeProxyAdmin)

# pangoro chain id
this_chain_pos=0
ChainMessageCommitter=$(deploy ChainMessageCommitter $this_chain_pos)
sig="initialize()"
data=$(seth calldata $sig)
ChainMessageCommitterProxy=$(deploy ChainMessageCommitterProxy \
  $ChainMessageCommitter \
  $BridgeProxyAdmin \
  $data)
