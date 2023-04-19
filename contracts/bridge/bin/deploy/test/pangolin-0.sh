#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=pangolin
export ETH_RPC_URL=https://pangolin-rpc.darwinia.network

echo "ETH_FROM: ${ETH_FROM}"

# import the deployment helpers
. $(dirname $0)/common.sh

BridgeProxyAdmin=$(deploy BridgeProxyAdmin)

ChainMessageCommitter=$(deploy ChainMessageCommitter)