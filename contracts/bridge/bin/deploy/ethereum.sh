#!/usr/bin/env bash

set -eo pipefail

unset SOURCE_CHAIN
unset TARGET_CHAIN
unset ETH_RPC_URL
export SOURCE_CHAIN=${from:?"!from"}

echo "ETH_FROM: ${ETH_FROM}"

# import the deployment helpers
. $(dirname $0)/base.sh

BridgeProxyAdmin=$(load_staddr "BridgeProxyAdmin")

export TARGET_CHAIN=${to:?"!to"}

# goerli to pangolin bridge config
# this_chain_pos=1
this_chain_pos=$(load_conf ".Chain.this_chain_pos")
# this_out_lane_pos=0
this_out_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[0].this_lane_pos")
# this_in_lane_pos=1
this_in_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[1].this_lane_pos")
# bridged_chain_pos=0
bridged_chain_pos=$(load_conf ".Chain.Lanes[0].bridged_chain_pos")
# bridged_in_lane_pos=1
bridged_in_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[0].bridged_lane_pos")
# bridged_out_lane_pos=0
bridged_out_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[1].bridged_lane_pos")
outlane_id=$(gen_lane_id "$bridged_in_lane_pos" "$bridged_chain_pos" "$this_out_lane_pos" "$this_chain_pos")
inlane_id=$(gen_lane_id "$bridged_out_lane_pos" "$bridged_chain_pos" "$this_in_lane_pos" "$this_chain_pos")
outlane_id=$(seth --to-uint256 $outlane_id)
inlane_id=$(seth --to-uint256 $inlane_id)

# fee market config
# https://etherscan.io/chart/gasprice
# 300000 wei * 100 gwei = 0.03 ether or 6000 RING
COLLATERAL_PERORDER=$(load_conf ".FeeMarket.collateral_perorder")
SLASH_TIME=$(load_conf ".FeeMarket.slash_time")
RELAY_TIME=$(load_conf ".FeeMarket.relay_time")
# price 2000 : 0.01
# 1000 : 999000
PRICE_RATIO=$(load_conf ".FeeMarket.price_ratio")
DUTY_RATIO=$(load_conf ".FeeMarket.duty_ratio")

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

# chain_id=$(seth --to-uint64 46) (46.to_be_bytes)
# seth keccak "${chain_id}Darwinia2::ecdsa-authority"
DOMAIN_SEPARATOR=$(load_conf ".LightClient.domain_separator")
relayers=$(load_conf ".LightClient.relayers")
threshold=$(load_conf ".LightClient.threshold")
nonce=$(load_conf ".LightClient.nonce")
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

max_gas_per_message=$(load_conf ".Chain.Lanes[0].lanes[1].max_gas_per_message")
SerialInboundLane=$(deploy SerialInboundLane \
  $DarwiniaMessageVerifier \
  $inlane_id \
  0 0 \
  $max_gas_per_message)

SETH_CHAIN=$SOURCE_CHAIN send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $SerialOutboundLane 1 --chain $SOURCE_CHAIN

EthereumSerialLaneVerifier=$(load_taddr "EthereumSerialLaneVerifier")
SETH_CHAIN=$TARGET_CHAIN send -F $ETH_FROM $EthereumSerialLaneVerifier "registry(uint,address,uint,address)" \
  $outlane_id $SerialOutboundLane $inlane_id $SerialInboundLane --chain $TARGET_CHAIN
