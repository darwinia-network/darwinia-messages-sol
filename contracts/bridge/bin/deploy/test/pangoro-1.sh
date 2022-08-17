#!/usr/bin/env bash

set -e

export NETWORK_NAME=pangoro
export TARGET_CHAIN=goerli
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
SLOT=356160
PROPOSER_INDEX=62
PARENT_ROOT=0x17f41e45fb2d5013a9665c1a700550c7b03b409fd6781ab574daa275f3ca2b08
STATE_ROOT=0xe78398fde45a0a5decafe8bda765c5ae8fd81e1813e2f12b2ceb66b393c3a9d2
BODY_ROOT=0x67c41c3fc65377e8e623b83fa2a70880f78c5cdf8634a1dfa59c4229d7a2e541
CURRENT_SYNC_COMMITTEE_HASH=0x4a4c2f918ec02c702138073f869530d694119f459598c2a487815cc1881822ff
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
