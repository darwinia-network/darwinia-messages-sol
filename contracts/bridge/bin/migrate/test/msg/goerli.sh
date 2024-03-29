#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=goerli
export TARGET_CHAIN=pangoro
export ETH_RPC_URL=https://rpc.ankr.com/eth_goerli

. $(dirname $0)/base.sh

old_outlane=$(load_saddr "OutboundLane")
FeeMarketProxy=$(load_saddr "FeeMarketProxy")
seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $old_outlane 0

# goerli to pangoro bridge config
this_chain_pos=1
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=0
bridged_in_lane_pos=1
bridged_out_lane_pos=0

POSALightClient=$(load_saddr "POSALightClient")
DarwiniaMessageVerifier=$(deploy DarwiniaMessageVerifier $POSALightClient)

OutboundLane=$(deploy OutboundLane \
  $DarwiniaMessageVerifier \
  $FeeMarketProxy \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

InboundLane=$(deploy InboundLane \
  $DarwiniaMessageVerifier \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $OutboundLane 1 --chain goerli

EthereumStorageVerifier=$(load_taddr "EthereumStorageVerifier")
(set -x; seth send -F $ETH_FROM $EthereumStorageVerifier "registry(uint32,uint32,address,uint32,address)" \
  $bridged_chain_pos $this_out_lane_pos $OutboundLane $this_in_lane_pos $InboundLane --rpc-url https://pangoro-rpc.darwinia.network)
