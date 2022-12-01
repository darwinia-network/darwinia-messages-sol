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

# darwinia to bsc bridge config
this_chain_pos=0
this_out_lane_pos=2
this_in_lane_pos=3
bridged_chain_pos=1
bridged_in_lane_pos=3
bridged_out_lane_pos=2

ParallelOutboundLane=$(deploy ParallelOutboundLane \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos)
