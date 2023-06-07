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

ChainMessageCommitter=$(deploy ChainMessageCommitter)

export TARGET_CHAIN=${to:?"!to"}

# darwinia to eth2.0 bridge config
# this_chain_pos=0
this_chain_pos=$(load_conf ".Chain.this_chain_pos")
# this_out_lane_pos=0
this_out_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[0].this_lane_pos")
# this_in_lane_pos=1
this_in_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[1].this_lane_pos")
# bridged_chain_pos=1
bridged_chain_pos=$(load_conf ".Chain.Lanes[1].bridged_chain_pos")
# bridged_in_lane_pos=1
bridged_in_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[0].bridged_lane_pos")
# bridged_out_lane_pos=0
bridged_out_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[1].bridged_lane_pos")
outlane_id=$(gen_lane_id "$bridged_in_lane_pos" "$bridged_chain_pos" "$this_out_lane_pos" "$this_chain_pos")
inlane_id=$(gen_lane_id "$bridged_out_lane_pos" "$bridged_chain_pos" "$this_in_lane_pos" "$this_chain_pos")
outlane_id=$(seth --to-uint256 $outlane_id)
inlane_id=$(seth --to-uint256 $inlane_id)

# fee market config
FEEMARKET_VAULT=$(load_conf ".FeeMarket.vault")
COLLATERAL_PERORDER=$(load_conf ".FeeMarket.${TARGET_CHAIN}.collateral_perorder")
ASSIGNED_RELAYERS_NUMBER=$(load_conf ".FeeMarket.${TARGET_CHAIN}.assigned_relayers_number")
SLASH_TIME=$(load_conf ".FeeMarket.${TARGET_CHAIN}.slash_time")
RELAY_TIME=$(load_conf ".FeeMarket.${TARGET_CHAIN}.relay_time")
# 0.01 : 2000
PRICE_RATIO=$(load_conf ".FeeMarket.${TARGET_CHAIN}.price_ratio")
DUTY_RATIO=$(load_conf ".FeeMarket.${TARGET_CHAIN}.duty_ratio")

FeeMarket=$(deploy FeeMarket \
  $FEEMARKET_VAULT \
  $COLLATERAL_PERORDER \
  $ASSIGNED_RELAYERS_NUMBER \
  $SLASH_TIME $RELAY_TIME \
  $PRICE_RATIO $DUTY_RATIO)

sig="initialize()"
data=$(seth calldata $sig)
FeeMarketProxy=$(deploy FeeMarketProxy \
  $FeeMarket \
  $BridgeProxyAdmin \
  $data)

# beacon light client config
BLS_PRECOMPILE=$(load_conf ".LightClient.bls_precompile")
SLOT=$(load_conf ".LightClient.slot")
PROPOSER_INDEX=$(load_conf ".LightClient.proposer_index")
PARENT_ROOT=$(load_conf ".LightClient.parent_root")
STATE_ROOT=$(load_conf ".LightClient.state_root")
BODY_ROOT=$(load_conf ".LightClient.body_root")
CURRENT_SYNC_COMMITTEE_HASH=$(load_conf ".LightClient.current_sync_committee_hash")
GENESIS_VALIDATORS_ROOT=$(load_conf ".LightClient.genesis_validators_root")

BeaconLightClient=$(deploy BeaconLightClient \
  $BLS_PRECOMPILE \
  $SLOT \
  $PROPOSER_INDEX \
  $PARENT_ROOT \
  $STATE_ROOT \
  $BODY_ROOT \
  $CURRENT_SYNC_COMMITTEE_HASH \
  $GENESIS_VALIDATORS_ROOT)

# import mandatory block reward
# reward=$(load_conf ".LightClient.mandatory_reward")
# BeaconLCMandatoryReward=$(deploy BeaconLCMandatoryReward $BeaconLightClient $reward)

EthereumSerialLaneVerifier=$(deploy EthereumSerialLaneVerifier $BeaconLightClient)

SerialOutboundLane=$(deploy SerialOutboundLane \
  $EthereumSerialLaneVerifier \
  $FeeMarketProxy \
  $outlane_id \
  1 0 0)

max_gas_per_message=$(load_conf ".Chain.Lanes[1].lanes[1].max_gas_per_message")
SerialInboundLane=$(deploy SerialInboundLane \
  $EthereumSerialLaneVerifier \
  $inlane_id \
  0 0 \
  $max_gas_per_message)

LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)
SETH_CHAIN=$SOURCE_CHAIN send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $SerialOutboundLane $SerialInboundLane --chain $SOURCE_CHAIN
SETH_CHAIN=$SOURCE_CHAIN send -F $ETH_FROM $ChainMessageCommitter "registry(address)" $LaneMessageCommitter --chain $SOURCE_CHAIN

SETH_CHAIN=$SOURCE_CHAIN send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $SerialOutboundLane 1 --chain $SOURCE_CHAIN
