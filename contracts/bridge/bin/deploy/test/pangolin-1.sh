#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=pangolin
export TARGET_CHAIN=goerli
export ETH_RPC_URL=https://pangolin-rpc.darwinia.network

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
SLOT=5101760
PROPOSER_INDEX=262949
PARENT_ROOT=0xeecc8ac3f7c20d755b9895d0adcf18bc767fce1926169841a3dd5d237347f8bb
STATE_ROOT=0xf7bcbde6217542b2ce6d14b3fecd2a39e03fbd16cf0b56716ca02c0c1ca270c5
BODY_ROOT=0x7e3bf9687187f50273643c0aa0153fe8747186ac5ec696e45e275768180153cf
CURRENT_SYNC_COMMITTEE_HASH=0x3e550c1ec5b6ce738f0f377dad7dabb3db732075bb2f716617bd2670326f51e2
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
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

SerialInboundLane=$(deploy SerialInboundLane \
  $EthereumSerialLaneVerifier \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $SerialOutboundLane $SerialInboundLane
seth send -F $ETH_FROM $ChainMessageCommitter "registry(address)" $LaneMessageCommitter

seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $SerialOutboundLane 1
