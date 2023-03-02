#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=goerli
export ETH_RPC_URL=https://rpc.ankr.com/eth_goerli

echo "ETH_FROM: ${ETH_FROM}"

# import the deployment helpers
. $(dirname $0)/common.sh

BridgeProxyAdmin=$(deploy BridgeProxyAdmin)

export TARGET_CHAIN=pangoro


# goerli to pangoro bridge config
this_chain_pos=1
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=0
bridged_in_lane_pos=1
bridged_out_lane_pos=0

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

# seth keccak "45Pangoro2::ecdsa-authority"
DOMAIN_SEPARATOR=0x6516caa5e629f7c38609c9a51c87c41bcae861829b3c6d4e540f727ede06fa51
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
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

outlaneid=$(seth call $SerialOutboundLane "getLaneId()(uint)")

SerialInboundLane=$(deploy SerialInboundLane \
  $DarwiniaMessageVerifier \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

inlaneid=$(seth call $SerialInboundLane "getLaneId()(uint)")

seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $SerialOutboundLane 1 --chain goerli

EthereumSerialLaneVerifier=$(jq -r ".[\"$NETWORK_NAME\"].EthereumSerialLaneVerifier" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json")
(set -x; seth send -F $ETH_FROM $EthereumSerialLaneVerifier "registry(uint,address,uint,address)" \
  $outlaneid $SerialOutboundLane $inlaneid $SerialInboundLane --rpc-url https://pangoro-rpc.darwinia.network)
