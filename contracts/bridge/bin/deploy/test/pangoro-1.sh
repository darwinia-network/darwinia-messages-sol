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
SLOT=122336
PROPOSER_INDEX=1447
PARENT_ROOT=0x1461f5735e1b8a6298832f6f9d5c95dc0497cef396ec4c699dc25ff7c54e1885
STATE_ROOT=0x5ae55f17a8c8974ced57b556e346a9af3a3d4fed1bdef9366298a4487f919442
BODY_ROOT=0x9465694f226465b704bf3b4a711cdfd23f6a3791484917faab15582687a80fb8
CURRENT_SYNC_COMMITTEE_HASH=0xd1fee9e7816719238fbea9deb5b845a09206ebd18113c63666b8f3eca1eac17b
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
  $ExecutionLayer \
  $FeeMarket \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

InboundLane=$(deploy InboundLane \
  $ExecutionLayer \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $OutboundLane $InboundLane
seth send -F $ETH_FROM $ChainMessageCommitter "registry(address)" $LaneMessageCommitter

seth send -F $ETH_FROM $FeeMarket "setOutbound(address,uint)" $OutboundLane 1
