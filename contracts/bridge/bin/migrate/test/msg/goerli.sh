#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=goerli
export TARGET_CHAIN=pangoro
export ETH_RPC_URL=https://rpc.ankr.com/eth_goerli

. $(dirname $0)/base.sh

load_saddr() {
  jq -r ".[\"$TARGET_CHAIN\"].\"$1\"" "$PWD/bin/addr/$MODE/$NETWORK_NAME.json"
}

load_taddr() {
  jq -r ".[\"$NETWORK_NAME\"].\"$1\"" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json"
}

old_outlane=$(load_saddr "OutboundLane")
FeeMarketProxy=$(load_saddr "FeeMarketProxy")
seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $old_outlane 0

# bsctest to pangoro bridge config
this_chain_pos=1
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=0
bridged_in_lane_pos=1
bridged_out_lane_pos=0

DarwiniaLightClientProxy=$(load_saddr "DarwiniaLightClientProxy")
DarwiniaMessageVerifier=$(deploy DarwiniaMessageVerifier $DarwiniaLightClientProxy)

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

DarwiniaLightClientProxy=$(load_taddr "EthereumStorageVerifier")
(set -x; seth send -F $ETH_FROM $EthereumStorageVerifier "registry(uint32,uint32,address,uint32,address)" \
  $bridged_chain_pos $this_out_lane_pos $OutboundLane $this_in_lane_pos $InboundLane --rpc-url https://pangoro-rpc.darwinia.network)
