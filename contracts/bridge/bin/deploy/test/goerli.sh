#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
unset SETH_CHAIN
export NETWORK_NAME=goerli
export SETH_CHAIN=goerli
# export ETH_RPC_URL=https://rpc.ankr.com/eth_goerli

echo "ETH_FROM: ${ETH_FROM}"

# import the deployment helpers
. $(dirname $0)/common.sh

BridgeProxyAdmin=$(deploy BridgeProxyAdmin)

export TARGET_CHAIN=pangolin


# goerli to pangolin bridge config
this_chain_pos=1
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=0
bridged_in_lane_pos=1
bridged_out_lane_pos=0
outlane_id=$(gen_lane_id "$bridged_in_lane_pos" "$bridged_chain_pos" "$this_out_lane_pos" "$this_chain_pos")
inlane_id=$(gen_lane_id "$bridged_out_lane_pos" "$bridged_chain_pos" "$this_in_lane_pos" "$this_chain_pos")
outlane_id=$(seth --to-uint256 $outlane_id)
inlane_id=$(seth --to-uint256 $inlane_id)

# fee market config
COLLATERAL_PERORDER=$(seth --to-wei 0.0001 ether)
SLASH_TIME=86400
RELAY_TIME=86400
# 300 : 0.01
PRICE_RATIO=100
DUTY_RATIO=30

SimpleFeeMarket=$(deploy SimpleFeeMarket \
  $COLLATERAL_PERORDER \
  $SLASH_TIME $RELAY_TIME \
  $PRICE_RATIO $DUTY_RATIO)

sig="initialize()"
data=$(seth calldata $sig)
FeeMarketProxy=$(deploy FeeMarketProxy \
  $SimpleFeeMarket \
  $BridgeProxyAdmin \
  $data)

# # darwinia beefy light client config
# # pangolin
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

# chain_id=$(seth --to-uint64 43) (43.to_be_bytes)
# seth keccak "${chain_id}Pangolin2::ecdsa-authority"
DOMAIN_SEPARATOR=0xe97c73e46305f3bca2279f002665725cd29e465c6624e83a135f7b2e6b1a8134
relayers=[0x68898db1012808808c903f390909c52d9f706749]
threshold=1
nonce=0

POSALightClient=$(deploy POSALightClient $DOMAIN_SEPARATOR \
  $relayers \
  $threshold \
  $nonce)

DarwiniaMessageVerifier=$(deploy DarwiniaMessageVerifier $POSALightClient)

SerialOutboundLane=$(deploy SerialOutboundLane \
  $DarwiniaMessageVerifier \
  $FeeMarketProxy \
  $outlane_id \
  1 0 0)

MAX_GAS_PER_MESSAGE=240000
SerialInboundLane=$(deploy SerialInboundLane \
  $DarwiniaMessageVerifier \
  $inlane_id \
  0 0 \
  $MAX_GAS_PER_MESSAGE)

seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $SerialOutboundLane 1 --chain goerli

EthereumSerialLaneVerifier=$(jq -r ".[\"$NETWORK_NAME\"].EthereumSerialLaneVerifier" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json")
# (set -x; seth send -F $ETH_FROM $EthereumSerialLaneVerifier "registry(uint,address,uint,address)" \
#   $outlane_id $SerialOutboundLane $inlane_id $SerialInboundLane --rpc-url https://pangoro-rpc.darwinia.network)

(set -x; seth send -F $ETH_FROM $EthereumSerialLaneVerifier "registry(uint,address,uint,address)" \
  $outlane_id $SerialOutboundLane $inlane_id $SerialInboundLane --rpc-url https://pangolin-rpc.darwinia.network)
