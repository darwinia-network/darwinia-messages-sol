#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# bsctest to pangolin bridge config
this_chain_pos=1
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=0
bridged_in_lane_pos=1
bridged_out_lane_pos=0

# fee market config
FEEMARKET_VAULT=0x0000000000000000000000000000000000000000
COLLATERAL_PERORDER=$(seth --to-wei 10 ether)
ASSIGNED_RELAYERS_NUMBER=3
SLASH_TIME=86400
RELAY_TIME=86400

FeeMarket=$(deploy FeeMarket $FEEMARKET_VAULT $COLLATERAL_PERORDER $ASSIGNED_RELAYERS_NUMBER $SLASH_TIME $RELAY_TIME)

# darwinia beefy light client config
NETWORK=0x6c6f63616c2d65766d0000000000000000000000000000000000000000000000
BEEFY_SLASH_VALUT=0x0000000000000000000000000000000000000000
BEEFY_VALIDATOR_SET_ID=0
BEEFY_VALIDATOR_SET_LEN=3
BEEFY_VALIDATOR_SET_ROOT=0x92622f8520ac4c57e72783387099b2bc696523782c5e5fae137faff102268e07
DarwiniaLightClient=$(deploy DarwiniaLightClient $NETWORK $BEEFY_SLASH_VALUT $BEEFY_VALIDATOR_SET_ID $BEEFY_VALIDATOR_SET_LEN $BEEFY_VALIDATOR_SET_ROOT)

OutboundLane=$(deploy OutboundLane $DarwiniaLightClient $this_chain_pos $this_out_lane_pos $bridged_chain_pos $bridged_in_lane_pos 1 0 0)
InboundLane=$(deploy InboundLane $DarwiniaLightClient $this_chain_pos $this_in_lane_pos $bridged_chain_pos $bridged_out_lane_pos 0 0)

seth send $OutboundLane "setFeeMarket(address)" $FeeMarket
seth send $FeeMarket "setOutbound(address,uint)" $OutboundLane 1

BSCLightClient=$(jq -r ".BSCLightClient" "$PWD/bin/addr/local-dvm.json")
ETH_FROM=0x6Be02d1d3665660d22FF9624b7BE0551ee1Ac91b ETH_RPC_URL=http://192.168.2.100:9933 seth send $BSCLightClient "registry(uint32,uint32,address,uint32,address)" $bridged_chain_pos $this_out_lane_pos $OutboundLane $this_in_lane_pos $InboundLane
