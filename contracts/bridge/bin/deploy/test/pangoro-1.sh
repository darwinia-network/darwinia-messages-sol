#!/usr/bin/env bash

set -e

export NETWORK_NAME=pangoro
export TARGET_CHAIN=sepolia
# export ETH_RPC_URL=https://pangoro-rpc.darwinia.network
export ETH_RPC_URL=http://35.247.165.91:9933

echo "ETH_FROM: ${ETH_FROM}"

. $(dirname $0)/base.sh
load-addresses

# darwinia to eth2.0 bridge config
this_chain_pos=0
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=1
bridged_in_lane_pos=1
bridged_out_lane_pos=0

# fee market config
FEEMARKET_VAULT=$ETH_FROM
COLLATERAL_PERORDER=$(seth --to-wei 10 ether)
ASSIGNED_RELAYERS_NUMBER=3
SLASH_TIME=86400
RELAY_TIME=86400
# 0.01 : 2000
PRICE_RATIO=999990

FeeMarket=$(deploy FeeMarket \
  $FEEMARKET_VAULT \
  $COLLATERAL_PERORDER \
  $ASSIGNED_RELAYERS_NUMBER \
  $SLASH_TIME $RELAY_TIME \
  $PRICE_RATIO)

# beacon light client config
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
SLOT=105728
PROPOSER_INDEX=50
PARENT_ROOT=0x281f08600981a103c91b0c3de9fa4fb11b84f404aab93e2aeac897e2f9f6f691
STATE_ROOT=0x815e1625aef94346f44f075b9e652cec9004f3f124a966360c38f4f9dbb3123f
BODY_ROOT=0x37dbe6372bed5fde1a347060abfccffd43f07f020aabe569576f804a83f2b3ae
CURRENT_SYNC_COMMITTEE_HASH=0xbbbec2f8eda5f6904d6833f25d1f40e2ccb9fe6c5fb161c06ee2bd0e7c2520e7
GENESIS_VALIDATORS_ROOT=0xd8ea171f3c94aea21ebc42a1ed61052acf3f9209c00e4efbaaddac09ed9b8078

BeaconLightClient=$(deploy BeaconLightClient \
  $BLS_PRECOMPILE \
  $SLOT \
  $PROPOSER_INDEX \
  $PARENT_ROOT \
  $STATE_ROOT \
  $BODY_ROOT \
  $CURRENT_SYNC_COMMITTEE_HASH \
  $GENESIS_VALIDATORS_ROOT)

ExecutionLayer=$(deploy ExecutionLayer $BeaconLightClient)

OutboundLane=$(deploy OutboundLane \
  $BeaconLightClient \
  $FeeMarket \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

InboundLane=$(deploy InboundLane \
  $BeaconLightClient \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $OutboundLane $InboundLane
seth send -F $ETH_FROM $ChainMessageCommitter "registry(address)" $LaneMessageCommitter

seth send -F $ETH_FROM $FeeMarket "setOutbound(address,uint)" $OutboundLane 1
