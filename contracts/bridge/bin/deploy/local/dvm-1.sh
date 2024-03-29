#!/usr/bin/env bash

set -e

export NETWORK_NAME=dvm
export TARGET_CHAIN=evm-eth2
export ETH_RPC_URL=${TEST_LOCAL_DVM_RPC:-http://192.168.2.100:9933}
export ETH_FROM=${TEST_LOCAL_DVM_FROM:-0x6Be02d1d3665660d22FF9624b7BE0551ee1Ac91b}

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

# beacon light client config
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
SLOT=651232
PROPOSER_INDEX=86325
PARENT_ROOT=0x13189ed59789d8c28c9e4f8aed4494979075cf3c0a1ee9fd03f93816f65bbe16
STATE_ROOT=0xd29f11a73f0207a356e38ad5dccdaa2fdf6c94aa9c51d34e6ca29ce9dbdd6550
BODY_ROOT=0x6a52c3e5c4d195607035457f4263b3a3a653d9b143bc73bef5ca5c1154b5c02d
CURRENT_SYNC_COMMITTEE_HASH=0x21053f2ba6bbb6c6d452697ea35aa1c77edfb48aae52612169d01290d90f7155
GENESIS_VALIDATORS_ROOT=0x99b09fcd43e5905236c370f184056bec6e6638cfc31a323b304fc4aa789cb4ad

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

OutboundLane=$(deploy OutboundLane \
  $ExecutionLayer \
  $FeeMarket \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

InboundLane=$(deploy InboundLane \
  $ExecutionLayer \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $OutboundLane $InboundLane
seth send -F $ETH_FROM $ChainMessageCommitter "registry(address)" $LaneMessageCommitter

seth send -F $ETH_FROM $FeeMarket "setOutbound(address,uint)" $OutboundLane 1

amount=$(seth --to-wei 1000 ether)
seth send -F $ETH_FROM -V $amount 0x3DFe30fb7b46b99e234Ed0F725B5304257F78992
seth send -F $ETH_FROM -V $amount 0xB3c5310Dcf15A852b81d428b8B6D5Fb684300DF9
seth send -F $ETH_FROM -V $amount 0xf4F07AAe298E149b902993B4300caB06D655f430
