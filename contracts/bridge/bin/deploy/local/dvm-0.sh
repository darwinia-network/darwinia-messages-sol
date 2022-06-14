#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=dvm
export ETH_RPC_URL=${TEST_LOCAL_DVM_RPC:-http://192.168.2.100:9933}
export ETH_FROM=${TEST_LOCAL_DVM_FROM:-0x6Be02d1d3665660d22FF9624b7BE0551ee1Ac91b}

echo "ETH_FROM: ${ETH_FROM}"

# import the deployment helpers
. $(dirname $0)/common.sh

# pangori chain id
this_chain_pos=0

ChainMessageCommitter=$(deploy ChainMessageCommitter $this_chain_pos)
