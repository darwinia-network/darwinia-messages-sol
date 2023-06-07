#!/usr/bin/env bash

set -eo pipefail

unset SOURCE_CHAIN
unset TARGET_CHAIN
export SOURCE_CHAIN=${from:?"!from"}
export TARGET_CHAIN=${to:?"!to"}
export SETH_CHAIN=$SOURCE_CHAIN

# export DAPP_VERBOSE=1

. $(dirname $0)/base.sh

BridgeProxyAdmin=$(load_staddr "BridgeProxyAdmin")
verify BridgeProxyAdmin $BridgeProxyAdmin

COLLATERAL_PERORDER=$(load_conf ".FeeMarket.${TARGET_CHAIN}.collateral_perorder")
SLASH_TIME=$(load_conf ".FeeMarket.${TARGET_CHAIN}.slash_time")
RELAY_TIME=$(load_conf ".FeeMarket.${TARGET_CHAIN}.relay_time")
PRICE_RATIO=$(load_conf ".FeeMarket.${TARGET_CHAIN}.price_ratio")
DUTY_RATIO=$(load_conf ".FeeMarket.${TARGET_CHAIN}.duty_ratio")
SimpleFeeMarket=$(load_saddr "SimpleFeeMarket")
verify SimpleFeeMarket $SimpleFeeMarket $COLLATERAL_PERORDER $SLASH_TIME $RELAY_TIME $PRICE_RATIO $DUTY_RATIO

FeeMarketProxy=$(load_saddr "FeeMarketProxy")
data=$(seth calldata "initialize()")
verify FeeMarketProxy $FeeMarketProxy $SimpleFeeMarket $BridgeProxyAdmin $data

DOMAIN_SEPARATOR=$(load_conf ".LightClient.domain_separator")
relayers=$(load_conf ".LightClient.relayers")
threshold=$(load_conf ".LightClient.threshold")
nonce=$(load_conf ".LightClient.nonce")
POSALightClient=$(load_saddr "POSALightClient")
verify POSALightClient $POSALightClient $DOMAIN_SEPARATOR \
  $relayers $threshold $nonce

DarwiniaMessageVerifier=$(load_saddr "DarwiniaMessageVerifier")
verify DarwiniaMessageVerifier $DarwiniaMessageVerifier $POSALightClient

# goerli to pangoro bridge config
this_chain_pos=$(load_conf ".Chain.this_chain_pos")
bridged_chain_pos=$(load_conf ".Chain.Lanes[0].bridged_chain_pos")
this_out_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[0].this_lane_pos")
bridged_in_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[0].bridged_lane_pos")
this_in_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[1].this_lane_pos")
bridged_out_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[1].bridged_lane_pos")
outlane_id=$(gen_lane_id "$bridged_in_lane_pos" "$bridged_chain_pos" "$this_out_lane_pos" "$this_chain_pos")
inlane_id=$(gen_lane_id "$bridged_out_lane_pos" "$bridged_chain_pos" "$this_in_lane_pos" "$this_chain_pos")
outlane_id=$(seth --to-uint256 $outlane_id)
inlane_id=$(seth --to-uint256 $inlane_id)

SerialOutboundLane=$(load_saddr "SerialOutboundLane")
verify SerialOutboundLane $SerialOutboundLane $DarwiniaMessageVerifier \
  $FeeMarketProxy \
  $outlane_id 1 0 0

max_gas_per_message=$(load_conf ".Chain.Lanes[0].lanes[1].max_gas_per_message")
SerialInboundLane=$(load_saddr "SerialInboundLane")
verify SerialInboundLane $SerialInboundLane $DarwiniaMessageVerifier \
  $inlane_id 0 0 $max_gas_per_message
