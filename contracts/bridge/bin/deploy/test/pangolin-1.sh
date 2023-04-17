#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
unset SETH_CHAIN
export NETWORK_NAME=pangolin
export TARGET_CHAIN=goerli
export SETH_CHAIN=pangolin
# export ETH_RPC_URL=https://pangolin-rpc.darwinia.network

echo "ETH_FROM: ${ETH_FROM}"

. $(dirname $0)/base.sh
load_addresses

# darwinia to eth2.0 bridge config
this_chain_pos=0
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=1
bridged_in_lane_pos=1
bridged_out_lane_pos=0
outlane_id=$(gen_lane_id "$bridged_in_lane_pos" "$bridged_chain_pos" "$this_out_lane_pos" "$this_chain_pos")
inlane_id=$(gen_lane_id "$bridged_out_lane_pos" "$bridged_chain_pos" "$this_in_lane_pos" "$this_chain_pos")
outlane_id=$(seth --to-uint256 $outlane_id)
inlane_id=$(seth --to-uint256 $inlane_id)

# fee market config
FEEMARKET_VAULT=$ETH_FROM
COLLATERAL_PERORDER=$(seth --to-wei 10 ether)
ASSIGNED_RELAYERS_NUMBER=3
SLASH_TIME=10800
RELAY_TIME=10800
# 0.01 : 2000
PRICE_RATIO=999900
DUTY_RATIO=20

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
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
SLOT=5433408
PROPOSER_INDEX=338940
PARENT_ROOT=0xf7c0374ad89d9a28f6708bd7b02af59a7a2ed2463a4ef191aa55cdf6cf8001b2
STATE_ROOT=0x9840d388c38172332553e9445e7fd64185aba5212026d22dce5efccf41d5663d
BODY_ROOT=0x4b6cc5f729ae6a9d57f6b912d655467627ce4d057f10a1d0a8ad5f68c5c1a2e9
CURRENT_SYNC_COMMITTEE_HASH=0x4bcc8065b1462577a9971110aaa3ea5630ce3e6bc0ecb53e54777ce7d4a5e816
GENESIS_VALIDATORS_ROOT=0x043db0d9a83813551ee2f33450d23797757d430911a9320530ad8a0eabc43efb

BeaconLightClient=$(deploy BeaconLightClient \
  $BLS_PRECOMPILE \
  $SLOT \
  $PROPOSER_INDEX \
  $PARENT_ROOT \
  $STATE_ROOT \
  $BODY_ROOT \
  $CURRENT_SYNC_COMMITTEE_HASH \
  $GENESIS_VALIDATORS_ROOT)

CAPELLA_FORK_EPOCH=162304
ExecutionLayer=$(deploy ExecutionLayer $BeaconLightClient $CAPELLA_FORK_EPOCH)

# import mandatory block reward
reward=$(seth --to-wei 1 ether)
BeaconLCMandatoryReward=$(deploy BeaconLCMandatoryReward $BeaconLightClient $reward)

EthereumSerialLaneVerifier=$(deploy EthereumSerialLaneVerifier $ExecutionLayer)

SerialOutboundLane=$(deploy SerialOutboundLane \
  $EthereumSerialLaneVerifier \
  $FeeMarketProxy \
  $outlane_id \
  1 0 0)

MAX_GAS_PER_MESSAGE=600000
SerialInboundLane=$(deploy SerialInboundLane \
  $EthereumSerialLaneVerifier \
  $inlane_id \
  0 0 \
  $MAX_GAS_PER_MESSAGE)

LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $SerialOutboundLane $SerialInboundLane
seth send -F $ETH_FROM $ChainMessageCommitter "registry(address)" $LaneMessageCommitter

seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $SerialOutboundLane 1
