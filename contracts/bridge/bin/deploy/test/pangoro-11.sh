#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
unset SETH_CHAIN
export NETWORK_NAME=pangoro
export TARGET_CHAIN=goerli
export SETH_CHAIN=goerli
# export ETH_RPC_URL=https://pangoro-rpc.darwinia.network

. $(dirname $0)/base.sh

load_saddr() {
  jq -r ".[\"$TARGET_CHAIN\"].\"$1\"" "$PWD/bin/addr/$MODE/$NETWORK_NAME.json"
}

load_taddr() {
  jq -r ".[\"$NETWORK_NAME\"].\"$1\"" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json"
}

cal() {
  python3 -c "print(int($1))"
}

# darwinia to bsc bridge config
this_chain_pos=0
this_out_lane_pos=2
this_in_lane_pos=3
bridged_chain_pos=1
bridged_in_lane_pos=3
bridged_out_lane_pos=2

lindex=$(cal "($this_chain_pos << 32) + $bridged_out_lane_pos")
lane_root_slot=1
ExecutionLayer=$(load_saddr "ExecutionLayer")
bridged_out_lane=$(load_taddr "ParallelOutboundLane")
EthereumParallelLaneStorageVerifier=$(deploy EthereumParallelLaneStorageVerifier \
  $lindex \
  $lane_root_slot \
  $ExecutionLayer \
  $bridged_out_lane)

ParallelInboundLane=$(deploy ParallelInboundLane \
  $EthereumParallelLaneStorageVerifier \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos)

LaneMessageCommitter=$(load_saddr "LaneMessageCommitter")
ParallelOutboundLane=$(load_saddr "ParallelOutboundLane")
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $ParallelOutboundLane $ParallelInboundLane
