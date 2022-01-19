#!/usr/bin/env bash

set -eo pipefail

export ETH_RPC_URL=http://192.168.2.100:9933
export ETH_FROM=0x6Be02d1d3665660d22FF9624b7BE0551ee1Ac91b

# import the deployment helpers
. $(dirname $0)/common.sh

# pangolin to bsctest bridge config
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
FEEMARKET_VAULT=0x0000000000000000000000000000000000000000
COLLATERAL_PERORDER=$(seth --to-wei 10 ether)
ASSIGNED_RELAYERS_NUMBER=3
SLASH_TIME=86400
RELAY_TIME=86400

FeeMarket=$(deploy FeeMarket $FEEMARKET_VAULT $COLLATERAL_PERORDER $ASSIGNED_RELAYERS_NUMBER $SLASH_TIME $RELAY_TIME)

BSCLightClient=$(deploy BSCLightClient $bridged_chain_pos $LANE_IDENTIFY_SLOT $LANE_NONCE_SLOT $LANE_MESSAGE_SLOT)

ChainMessageCommitter=$(deploy ChainMessageCommitter $this_chain_pos)
LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)

OutboundLane=$(deploy OutboundLane $BSCLightClient $this_chain_pos $this_out_lane_pos $bridged_chain_pos $bridged_in_lane_pos 1 0 0)
InboundLane=$(deploy InboundLane $BSCLightClient $this_chain_pos $this_in_lane_pos $bridged_chain_pos $bridged_out_lane_pos 0 0)

seth send $ChainMessageCommitter "registry(address)" $LaneMessageCommitter
seth send $LaneMessageCommitter "registry(address,address)" $OutboundLane $InboundLane
seth send $OutboundLane "setFeeMarket(address)" $FeeMarket
seth send $FeeMarket "setOutbound(address,uint)" $OutboundLane 1
