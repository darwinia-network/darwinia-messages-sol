#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=pangoro
export TARGET_CHAIN=goerli
# export ETH_RPC_URL=https://pangoro-rpc.darwinia.network
export ETH_RPC_URL=http://35.247.165.91:9933

echo "ETH_FROM: ${ETH_FROM}"

. $(dirname $0)/base.sh
load-addresses

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
SLASH_TIME=86400
RELAY_TIME=86400
# 0.01 : 2000
PRICE_RATIO=999990

FeeMarket=$(deploy FeeMarket \
  $FEEMARKET_VAULT \
  $COLLATERAL_PERORDER \
  $ASSIGNED_RELAYERS_NUMBER \
  $SLASH_TIME $RELAY_TIME \
  $PRICE_RATIO)

sig="initialize()"
data=$(seth calldata $sig)
FeeMarketProxy=$(deploy FeeMarketProxy \
  $FeeMarket \
  $BridgeProxyAdmin \
  $data)

# beacon light client config
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
SLOT=3920608
PROPOSER_INDEX=3000
PARENT_ROOT=0x9ee28cd422cea448946a79d1dacd2ffcdd7b8170b932baf541c6d14a904477b6
STATE_ROOT=0x467168bd7ad1bfa51821af7aabeabdc2403388adcd1b835f6f5aa7760e08cadb
BODY_ROOT=0xcacec3003756ee10cb7aa346f7f575d1ef21653add967cf798b401258cf9745e
CURRENT_SYNC_COMMITTEE_HASH=0x1eb40046542f46b890d4fab007451feb5665ef3f47ae37d1fc742f44b780d4ef
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

ExecutionLayer=$(deploy ExecutionLayer $BeaconLightClient)

EthereumStorageVerifier=$(deploy EthereumStorageVerifier $ExecutionLayer)

OutboundLane=$(deploy OutboundLane \
  $EthereumStorageVerifier \
  $FeeMarketProxy \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

InboundLane=$(deploy InboundLane \
  $EthereumStorageVerifier \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $OutboundLane $InboundLane
seth send -F $ETH_FROM $ChainMessageCommitterProxy "registry(address)" $LaneMessageCommitter

seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $OutboundLane 1
