#!/usr/bin/env bash

set -e

export NETWORK_NAME=pangoro
export TARGET_CHAIN=ropsten
export ETH_RPC_URL=https://pangoro-rpc.darwinia.network
# export ETH_RPC_URL=http://35.247.165.91:9933

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

# becon light client config
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
SLOT=594880
PROPOSER_INDEX=62817
PARENT_ROOT=0x961949592705567a50aae3f4186852f44dfeeb9688df46f7f49ef4a626f60b9a
STATE_ROOT=0x768a9a1694fd36f6d9523be1e49b690dc4ab2934ba46fa99ad110f03b4a785c4
BODY_ROOT=0x2983d20d70763f6d1e619f98f83e9ba7a8a84e7b10d82085e4e192c6ff2b9b76
CURRENT_SYNC_COMMITTEE_HASH=0x9c27f72afdc11a64a3f0c7246fe5ed2aa6303a1cb06bb0a7be746528ee97741d
GENESIS_VALIDATORS_ROOT=0x99b09fcd43e5905236c370f184056bec6e6638cfc31a323b304fc4aa789cb4ad

BeaconLightClient=$(deploy BeaconLightClient \
  $BLS_PRECOMPILE \
  $SLOT \
  $PROPOSER_INDEX \
  $PARENT_ROOT \
  $STATE_ROOT \
  $BODY_ROOT \
  $CURRENT_SYNC_COMMITTEE_HASH \
  $GENESIS_VALIDATORS_ROOT)

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