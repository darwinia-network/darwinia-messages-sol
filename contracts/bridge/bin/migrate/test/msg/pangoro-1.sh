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

old_outlane=$(load_saddr "OutboundLane")
FeeMarketProxy=$(load_saddr "FeeMarketProxy")
seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $old_outlane 0

# darwinia to eth2.0 bridge config
this_chain_pos=0
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=1
bridged_in_lane_pos=1
bridged_out_lane_pos=0

EthereumExecutionLayerProxy=$(load_saddr "EthereumExecutionLayerProxy")
EthereumStorageVerifier=$(deploy EthereumStorageVerifier $EthereumExecutionLayerProxy)

OutboundLane=$(deploy OutboundLane \
  $EthereumStorageVerifier \
  $FeeMarketProxy \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

InboundLane=$(deploy InboundLane \
  $EthereumStorageVerifier \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $OutboundLane $InboundLane
ChainMessageCommitterProxy=$(cat $ADDRESSES_FILE | jq -r ".ChainMessageCommitterProxy")
seth send -F $ETH_FROM $ChainMessageCommitterProxy "registry(address)" $LaneMessageCommitter

seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $OutboundLane 1
