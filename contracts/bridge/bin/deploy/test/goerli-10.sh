#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=goerli
export TARGET_CHAIN=pangolin
export ETH_RPC_URL=https://rpc.ankr.com/eth_goerli

echo "ETH_FROM: ${ETH_FROM}"

# import the deployment helpers
. $(dirname $0)/base.sh

# bsctest to pangoro bridge config
this_chain_pos=1
this_out_lane_pos=2
this_in_lane_pos=3
bridged_chain_pos=0
bridged_in_lane_pos=3
bridged_out_lane_pos=2


ParallelOutboundLane=$(deploy ParallelOutboundLane \
  $FeeMarketProxy \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos)
