#!/usr/bin/env bash

set -eo pipefail

export NETWORK_NAME=local-dvm-1
export ETH_RPC_URL=${TEST_LOCAL_DVM_RPC:-http://192.168.2.100:9933}
export ETH_FROM=${TEST_LOCAL_DVM_FROM:-0x6Be02d1d3665660d22FF9624b7BE0551ee1Ac91b}

# import the deployment helpers
. $(dirname $0)/common.sh

# darwinia to eth2.0 bridge config
this_chain_pos=0
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=1
bridged_in_lane_pos=1
bridged_out_lane_pos=0

# fee market config
FEEMARKET_VAULT=0x0000000000000000000000000000000000000000
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
BLS_PRECOMPILE=0x000000000000000000000000000000000000001c
SLOT=0
PROPOSER_INDEX=0
PARENT_ROOT=
STATE_ROOT=
BODY_ROOT=
CURRENT_SYNC_COMMITTEE_HASH=
NEXT_SYNC_COMMITTEE_HASH=

BeaconLightClient=$(deploy BeaconLightClient \
  $BLS_PRECOMPILE \
  $SLOT \
  $PROPOSER_INDEX \
  $PARENT_ROOT \
  $STATE_ROOT \
  $BODY_ROOT \
  $CURRENT_SYNC_COMMITTEE_HASH \
  $NEXT_SYNC_COMMITTEE_HASH)

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

ChainMessageCommitter=$(deploy ChainMessageCommitter $this_chain_pos)
LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)

seth send -F $ETH_FROM $ChainMessageCommitter "registry(address)" $LaneMessageCommitter
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $OutboundLane $InboundLane
seth send -F $ETH_FROM $FeeMarket "setOutbound(address,uint)" $OutboundLane 1

amount=$(seth --to-wei 1000 ether)
seth send -F $ETH_FROM -V $amount 0x3DFe30fb7b46b99e234Ed0F725B5304257F78992
seth send -F $ETH_FROM -V $amount 0xB3c5310Dcf15A852b81d428b8B6D5Fb684300DF9
seth send -F $ETH_FROM -V $amount 0xf4F07AAe298E149b902993B4300caB06D655f430
