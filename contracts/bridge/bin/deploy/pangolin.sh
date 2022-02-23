#!/usr/bin/env bash

set -eo pipefail

export NETWORK_NAME=pangolin
# export ETH_RPC_URL=http://pangolin-rpc.darwinia.network
export ETH_RPC_URL=http://34.69.228.225:9933

echo "ETH_FROM: ${ETH_FROM}"

# import the deployment helpers
. $(dirname $0)/common.sh

# pangolin to bsc bridge config
this_chain_pos=0
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=1
bridged_in_lane_pos=1
bridged_out_lane_pos=0
LANE_IDENTIFY_SLOT=0
LANE_NONCE_SLOT=1
LANE_MESSAGE_SLOT=2

# fee market config
FEEMARKET_VAULT=$ETH_FROM
COLLATERAL_PERORDER=$(seth --to-wei 10 ether)
ASSIGNED_RELAYERS_NUMBER=3
# 1 day
SLASH_TIME=86400
RELAY_TIME=86400

FeeMarket=$(deploy FeeMarket $FEEMARKET_VAULT $COLLATERAL_PERORDER $ASSIGNED_RELAYERS_NUMBER $SLASH_TIME $RELAY_TIME)

BSCLightClient=$(deploy BSCLightClient $bridged_chain_pos $LANE_IDENTIFY_SLOT $LANE_NONCE_SLOT $LANE_MESSAGE_SLOT)

ChainMessageCommitter=$(deploy ChainMessageCommitter $this_chain_pos)
LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)

OutboundLane=$(deploy OutboundLane $BSCLightClient $this_chain_pos $this_out_lane_pos $bridged_chain_pos $bridged_in_lane_pos 1 0 0)
InboundLane=$(deploy InboundLane $BSCLightClient $this_chain_pos $this_in_lane_pos $bridged_chain_pos $bridged_out_lane_pos 0 0)

seth send -F $ETH_FROM $ChainMessageCommitter "registry(address)" $LaneMessageCommitter --chain pangolin
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $OutboundLane $InboundLane --chain pangolin
seth send -F $ETH_FROM $OutboundLane "setFeeMarket(address)" $FeeMarket --chain pangolin
seth send -F $ETH_FROM $FeeMarket "setOutbound(address,uint)" $OutboundLane 1 --chain pangolin
