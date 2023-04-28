#!/usr/bin/env bash

set -eo pipefail

unset SOURCE_CHAIN
unset TARGET_CHAIN
export SOURCE_CHAIN=${from:?"!from"}
export SETH_CHAIN=$SOURCE_CHAIN

# export DAPP_VERBOSE=1

. $(dirname $0)/base.sh

ChainMessageCommitter=$(load_staddr "ChainMessageCommitter")
export TARGET_CHAIN=${to:?"!to"}

BridgeProxyAdmin=$(load_staddr "BridgeProxyAdmin")
# verify BridgeProxyAdmin $BridgeProxyAdmin

FEEMARKET_VAULT=$(load_conf ".FeeMarket.vault")
COLLATERAL_PERORDER=$(load_conf ".FeeMarket.collateral_perorder")
ASSIGNED_RELAYERS_NUMBER=$(load_conf ".FeeMarket.assigned_relayers_number")
SLASH_TIME=$(load_conf ".FeeMarket.slash_time")
RELAY_TIME=$(load_conf ".FeeMarket.relay_time")
PRICE_RATIO=$(load_conf ".FeeMarket.price_ratio")
DUTY_RATIO=$(load_conf ".FeeMarket.duty_ratio")
FeeMarket=$(load_saddr "FeeMarket")
verify FeeMarket $FeeMarket \
  $FEEMARKET_VAULT \
  $COLLATERAL_PERORDER \
  $ASSIGNED_RELAYERS_NUMBER \
  $SLASH_TIME $RELAY_TIME \
  $PRICE_RATIO $DUTY_RATIO


FeeMarketProxy=$(load_saddr "FeeMarketProxy")
data=$(seth calldata "initialize()")
verify FeeMarketProxy $FeeMarketProxy $FeeMarket $BridgeProxyAdmin $data

BLS_PRECOMPILE=$(load_conf ".LightClient.bls_precompile")
SLOT=$(load_conf ".LightClient.slot")
PROPOSER_INDEX=$(load_conf ".LightClient.proposer_index")
PARENT_ROOT=$(load_conf ".LightClient.parent_root")
STATE_ROOT=$(load_conf ".LightClient.state_root")
BODY_ROOT=$(load_conf ".LightClient.body_root")
CURRENT_SYNC_COMMITTEE_HASH=$(load_conf ".LightClient.current_sync_committee_hash")
GENESIS_VALIDATORS_ROOT=$(load_conf ".LightClient.genesis_validators_root")
BeaconLightClient=$(load_saddr "BeaconLightClient")
verify BeaconLightClient $BeaconLightClient \
  $BLS_PRECOMPILE \
  $SLOT \
  $PROPOSER_INDEX \
  $PARENT_ROOT \
  $STATE_ROOT \
  $BODY_ROOT \
  $CURRENT_SYNC_COMMITTEE_HASH \
  $GENESIS_VALIDATORS_ROOT

EthereumSerialLaneVerifier=$(load_saddr "EthereumSerialLaneVerifier")
verify EthereumSerialLaneVerifier $EthereumSerialLaneVerifier $BeaconLightClient

this_chain_pos=$(load_conf ".Chain.this_chain_pos")
this_out_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[0].this_lane_pos")
this_in_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[1].this_lane_pos")
bridged_chain_pos=$(load_conf ".Chain.Lanes[1].bridged_chain_pos")
bridged_in_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[0].bridged_lane_pos")
bridged_out_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[1].bridged_lane_pos")
outlane_id=$(gen_lane_id "$bridged_in_lane_pos" "$bridged_chain_pos" "$this_out_lane_pos" "$this_chain_pos")
inlane_id=$(gen_lane_id "$bridged_out_lane_pos" "$bridged_chain_pos" "$this_in_lane_pos" "$this_chain_pos")
outlane_id=$(seth --to-uint256 $outlane_id)
inlane_id=$(seth --to-uint256 $inlane_id)

SerialOutboundLane=$(load_saddr "SerialOutboundLane")
verify SerialOutboundLane $SerialOutboundLane $EthereumSerialLaneVerifier \
  $FeeMarketProxy \
  $outlane_id 1 0 0

max_gas_per_message=$(load_conf ".Chain.Lanes[1].lanes[1].max_gas_per_message")
SerialInboundLane=$(load_saddr "SerialInboundLane")
verify SerialInboundLane $SerialInboundLane $EthereumSerialLaneVerifier \
  $inlane_id 0 0 $max_gas_per_message

LaneMessageCommitter=$(load_saddr "LaneMessageCommitter")
verify LaneMessageCommitter $LaneMessageCommitter $this_chain_pos $bridged_chain_pos

verify ChainMessageCommitter $ChainMessageCommitter

