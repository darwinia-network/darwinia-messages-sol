#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=bsctest
export TARGET_CHAIN=pangoro
export ETH_RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545

echo "ETH_FROM: ${ETH_FROM}"

# import the deployment helpers
. $(dirname $0)/common.sh

# bsctest to pangoro bridge config
this_chain_pos=2
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=0
bridged_in_lane_pos=1
bridged_out_lane_pos=0

# fee market config
COLLATERAL_PERORDER=$(seth --to-wei 0.01 ether)
SLASH_TIME=86400
RELAY_TIME=86400
# 300 : 0.01
PRICE_RATIO=100

SimpleFeeMarket=$(deploy SimpleFeeMarket $COLLATERAL_PERORDER $SLASH_TIME $RELAY_TIME $PRICE_RATIO)

# # darwinia beefy light client config
# # Pangoro
# NETWORK=0x50616e676f726f00000000000000000000000000000000000000000000000000
# BEEFY_SLASH_VALUT=$ETH_FROM
# BEEFY_VALIDATOR_SET_ID=0
# BEEFY_VALIDATOR_SET_LEN=4
# BEEFY_VALIDATOR_SET_ROOT=0xde562c60e8a03c61ef0ab761968c14b50b02846dd35ab9faa9dea09d00247600
# DarwiniaLightClient=$(deploy DarwiniaLightClient \
#   $NETWORK \
#   $BEEFY_SLASH_VALUT \
#   $BEEFY_VALIDATOR_SET_ID \
#   $BEEFY_VALIDATOR_SET_LEN \
#   $BEEFY_VALIDATOR_SET_ROOT)

# seth keccak "45Pangoro::ecdsa-authority"
DOMAIN_SEPARATOR=0x38a6d9f96ef6e79768010f6caabfe09abc43e49792d5c787ef0d4fc802855947
relayers=[0x68898db1012808808c903f390909c52d9f706749]
threshold=1
nonce=0
POSALightClient=$(deploy POSALightClient \
  $DOMAIN_SEPARATOR \
  $relayers \
  $threshold \
  $nonce)

OutboundLane=$(deploy OutboundLane \
  $POSALightClient \
  $SimpleFeeMarket \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

InboundLane=$(deploy InboundLane \
  $POSALightClient \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

seth send -F $ETH_FROM $SimpleFeeMarket "setOutbound(address,uint)" $OutboundLane 1 --chain bsctest

BSCLightClient=$(jq -r ".[\"$NETWORK_NAME\"].BSCLightClient" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json")
(set -x; seth send -F $ETH_FROM $BSCLightClient "registry(uint32,uint32,address,uint32,address)" $bridged_chain_pos $this_out_lane_pos $OutboundLane $this_in_lane_pos $InboundLane --rpc-url https://pangoro-rpc.darwinia.network)
