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
bridged_out_lan=
EthereumParallelLaneStorageVerifier=$(deploy EthereumParallelLaneStorageVerifier \
  $lindex \
  $lane_root_slot \
  $ExecutionLayer \
  $bridged_out_lane)

ParallelOutboundLane=$(deploy ParallelOutboundLane \
  $BSCStorageVerifier \
  $FeeMarketProxy \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

InboundLane=$(deploy InboundLane \
  $BSCStorageVerifier \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $OutboundLane $InboundLane
ChainMessageCommitterProxy=$(cat $ADDRESSES_FILE | jq -r ".ChainMessageCommitterProxy")
seth send -F $ETH_FROM $ChainMessageCommitterProxy "registry(address)" $LaneMessageCommitter

seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $OutboundLane 1
