#!/usr/bin/env bash

set -e

export NETWORK_NAME=goerli
export TARGET_CHAIN=pangolin

# export DAPP_VERBOSE=1

. $(dirname $0)/base.sh

BridgeProxyAdmin=$(load_staddr "BridgeProxyAdmin")
verify BridgeProxyAdmin $BridgeProxyAdmin

COLLATERAL_PERORDER=$(load_conf ".FeeMarket.collateral_perorder")
SLASH_TIME=$(load_conf ".FeeMarket.slash_time")
RELAY_TIME=$(load_conf ".FeeMarket.relay_time")
PRICE_RATIO=$(load_conf ".FeeMarket.price_ratio")
SimpleFeeMarket=$(load_saddr "SimpleFeeMarket")
verify SimpleFeeMarket $SimpleFeeMarket $COLLATERAL_PERORDER $SLASH_TIME $RELAY_TIME $PRICE_RATIO

FeeMarketProxy=$(load_saddr "FeeMarketProxy")
data=$(seth calldata "initialize()")
verify FeeMarketProxy $FeeMarketProxy $SimpleFeeMarket $BridgeProxyAdmin $data

DOMAIN_SEPARATOR=$(load_conf ".DarwiniaLightClient.domain_separator")
POSALightClient=$(load_saddr "POSALightClient")
verify POSALightClient $POSALightClient $DOMAIN_SEPARATOR

relayers=$(load_conf ".DarwiniaLightClient.relayers")
threshold=$(load_conf ".DarwiniaLightClient.threshold")
nonce=$(load_conf ".DarwiniaLightClient.nonce")
sig="initialize(address[],uint256,uint256)"
data=$(seth calldata $sig \
  $relayers \
  $threshold \
  $nonce)
DarwiniaLightClientProxy=$(load_saddr "DarwiniaLightClientProxy")
verify DarwiniaLightClientProxy $DarwiniaLightClientProxy $POSALightClient $BridgeProxyAdmin $data

DarwiniaMessageVerifier=$(load_saddr "DarwiniaMessageVerifier")
verify DarwiniaMessageVerifier $DarwiniaMessageVerifier $DarwiniaLightClientProxy

# goerli to pangoro bridge config
this_chain_pos=$(load_conf ".Chain.this_chain_pos")
bridged_chain_pos=$(load_conf ".Chain.Lanes[0].bridged_chain_pos")
this_out_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[0].this_lane_pos")
bridged_in_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[0].bridged_lane_pos")
this_in_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[1].this_lane_pos")
bridged_out_lane_pos=$(load_conf ".Chain.Lanes[0].lanes[1].bridged_lane_pos")

OutboundLane=$(load_saddr "OutboundLane")
verify OutboundLane $OutboundLane $DarwiniaMessageVerifier \
  $FeeMarketProxy \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0

InboundLane=$(load_saddr "InboundLane")
verify InboundLane $InboundLane $DarwiniaMessageVerifier \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0
