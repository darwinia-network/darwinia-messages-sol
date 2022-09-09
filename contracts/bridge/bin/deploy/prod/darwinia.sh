#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=darwinia
export ETH_RPC_URL=https://rpc.darwinia.network

echo "ETH_FROM: ${ETH_FROM}"

. $(dirname $0)/common.sh

BridgeProxyAdmin=$(deploy BridgeProxyAdmin)

# darwinia chain id
this_chain_pos=0
ChainMessageCommitter=$(deploy ChainMessageCommitter $this_chain_pos)
sig="initialize()"
data=$(seth calldata $sig)
ChainMessageCommitterProxy=$(deploy ChainMessageCommitterProxy \
  $ChainMessageCommitter \
  $BridgeProxyAdmin \
  $data)

export TARGET_CHAIN=ethlive

# darwinia to ethlive bridge config
this_chain_pos=0
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=1
bridged_in_lane_pos=1
bridged_out_lane_pos=0

# TODO: fee market config
Multisig=
FEEMARKET_VAULT=$Multisig
# https://etherscan.io/chart/gasprice
# 300000 wei * 10 * 20 gwei = 0.06 ether or 12000 RING
# 12000 / 3 = 4000 RING
COLLATERAL_PERORDER=$(seth --to-wei 5000 ether)
ASSIGNED_RELAYERS_NUMBER=3
RELAY_TIME=3600
SLASH_TIME=10800
# price 0.01 : 2000
# 300 : 999700
PRICE_RATIO=999700

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

# TODO: beacon light client config
# double check
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
SLOT=4648192
PROPOSER_INDEX=316902
PARENT_ROOT=0xfcedfe920b02c49b9ceb12fb6c65e7143cbdfec7801dfb7da0e17952606cc9e5
STATE_ROOT=0x0cb1396c057879dccad7f31108929540d52370a7ee5602b1b7fa0ef0979d9b53
BODY_ROOT=0xc06a1688effcf77ab5512e002dea9bc5157cac10bb65faab4a52d58b9df83494
CURRENT_SYNC_COMMITTEE_HASH=0x7136174c4e3f656371dfd1e33e0d2d2470b6e376bd365106c54566a5450f98a7
GENESIS_VALIDATORS_ROOT=0x4b363db94e286120d76eb905340fdd4e54bfe9f06bf33ff6cf5ad27f511bfe95

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
sig=$(seth sig "initialize()")
data=$(seth calldata $sig)
EthereumExecutionLayerProxy=$(deploy EthereumExecutionLayerProxy \
  $ExecutionLayer \
  $BridgeProxyAdmin \
  $data)

EthereumStorageVerifier=$(deploy EthereumStorageVerifier $EthereumExecutionLayerProxy)

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
