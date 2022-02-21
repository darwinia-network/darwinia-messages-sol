#!/usr/bin/env bash

set -eo pipefail

export NETWORK_NAME=bsctest
export ETH_RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545
export VERIFY_CONTRACT=yes

echo "ETH_FROM: ${ETH_FROM}"

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
FEEMARKET_VAULT=$ETH_FROM
COLLATERAL_PERORDER=$(seth --to-wei 0.01 ether)
ASSIGNED_RELAYERS_NUMBER=3
SLASH_TIME=86400
RELAY_TIME=86400

FeeMarket=$(deploy FeeMarket $FEEMARKET_VAULT $COLLATERAL_PERORDER $ASSIGNED_RELAYERS_NUMBER $SLASH_TIME $RELAY_TIME)

# darwinia beefy light client config
# Pangolin
NETWORK=0x50616e676f6c696e000000000000000000000000000000000000000000000000
BEEFY_SLASH_VALUT=$ETH_FROM
BEEFY_VALIDATOR_SET_ID=0
BEEFY_VALIDATOR_SET_LEN=4
BEEFY_VALIDATOR_SET_ROOT=0xde562c60e8a03c61ef0ab761968c14b50b02846dd35ab9faa9dea09d00247600
DarwiniaLightClient=$(deploy DarwiniaLightClient $NETWORK $BEEFY_SLASH_VALUT $BEEFY_VALIDATOR_SET_ID $BEEFY_VALIDATOR_SET_LEN $BEEFY_VALIDATOR_SET_ROOT)

OutboundLane=$(deploy OutboundLane $DarwiniaLightClient $this_chain_pos $this_out_lane_pos $bridged_chain_pos $bridged_in_lane_pos 1 0 0)
InboundLane=$(deploy InboundLane $DarwiniaLightClient $this_chain_pos $this_in_lane_pos $bridged_chain_pos $bridged_out_lane_pos 0 0)

seth send -F $ETH_FROM $OutboundLane "setFeeMarket(address)" $FeeMarket --chain bsctest
seth send -F $ETH_FROM $FeeMarket "setOutbound(address,uint)" $OutboundLane 1 --chain bsctest

BSCLightClient=$(jq -r ".BSCLightClient" "$PWD/bin/addr/pangolin.json")
seth send -F $ETH_FROM $BSCLightClient "registry(uint32,uint32,address,uint32,address)" $bridged_chain_pos $this_out_lane_pos $OutboundLane $this_in_lane_pos $InboundLane --chain pangolin
