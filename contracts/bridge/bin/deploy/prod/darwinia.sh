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

# fee market config
HelixDaoMultisig=0xBd1a110ec476b4775c43905000288881367B1a88
FEEMARKET_VAULT=$HelixDaoMultisig
# https://etherscan.io/chart/gasprice
# 300000 wei * 100 gwei = 0.03 ether or 6000 RING
COLLATERAL_PERORDER=$(seth --to-wei 6000 ether)
ASSIGNED_RELAYERS_NUMBER=1
RELAY_TIME=10800
SLASH_TIME=10800
# price 0.01 : 2000
# 1000 : 999000
PRICE_RATIO=999000
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

# TODO: beacon light client config
# double check
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
SLOT=4778944
PROPOSER_INDEX=35443
PARENT_ROOT=0xc2e07ff697bfc45ca9b8253175b62077d0fe6d748d1b85b346a6c7fb6cb2410d
STATE_ROOT=0x33aff789985de14f665691b742f4d50f90583aac26aabd20fc7210e7978e4837
BODY_ROOT=0x16635199ee0698bfcf0ed1dfbf866274d4d23b6a7c19572487c31c7f6f71a7e9
CURRENT_SYNC_COMMITTEE_HASH=0xb2520d951e21fd83c81cb89b919091ed253e664a1f996b70f9ef61d00d469a8d
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

# import mandatory block reward
reward=$(seth --to-wei 1 ether)
BeaconLCMandatoryReward=$(deploy BeaconLCMandatoryReward $BeaconLightClient $reward)

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
