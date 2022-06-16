#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=local-evm-eth2
export TARGET_CHAIN=local-dvm
export ETH_RPC_URL=${TEST_LOCAL_EVM_RPC:-http://127.0.0.1:8545}
export ETH_FROM=${TEST_LOCAL_EVM_FROM:-$(seth ls --keystore $TMPDIR/8545/keystore | cut -f1)}
export ETH_RPC_ACCOUNTS=true

echo "ETH_FROM: ${ETH_FROM}"

# import the deployment helpers
. $(dirname $0)/common.sh

# ropsten to pangoro bridge config
this_chain_pos=1
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=0
bridged_in_lane_pos=1
bridged_out_lane_pos=0

# fee market config
COLLATERAL_PERORDER=$(seth --to-wei 0.01 ether)
SLASH_TIME=86400
RELAY_TIME=86400
# 2000 : 0.01
PRICE_RATIO=10

SimpleFeeMarket=$(deploy SimpleFeeMarket $COLLATERAL_PERORDER $SLASH_TIME $RELAY_TIME $PRICE_RATIO)

# darwinia beefy light client config
# Pangoro
NETWORK=0x50616e676f726f00000000000000000000000000000000000000000000000000
BEEFY_SLASH_VALUT=$ETH_FROM
BEEFY_VALIDATOR_SET_ID=0
BEEFY_VALIDATOR_SET_LEN=4
BEEFY_VALIDATOR_SET_ROOT=0xde562c60e8a03c61ef0ab761968c14b50b02846dd35ab9faa9dea09d00247600
DarwiniaLightClient=$(deploy DarwiniaLightClient \
  $NETWORK \
  $BEEFY_SLASH_VALUT \
  $BEEFY_VALIDATOR_SET_ID \
  $BEEFY_VALIDATOR_SET_LEN \
  $BEEFY_VALIDATOR_SET_ROOT)

OutboundLane=$(deploy OutboundLane \
  $DarwiniaLightClient \
  $SimpleFeeMarket \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

InboundLane=$(deploy InboundLane \
  $DarwiniaLightClient \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

seth send -F $ETH_FROM $SimpleFeeMarket "setOutbound(address,uint)" $OutboundLane 1 --chain bsctest

BeaconLightClient=$(jq -r ".[\"$NETWORK_NAME\"].BeaconLightClient" "$PWD/bin/addr/$TARGET_CHAIN.json")
(set -x; seth send -F 0x6Be02d1d3665660d22FF9624b7BE0551ee1Ac91b $BeaconLightClient "registry(uint32,uint32,address,uint32,address)" $bridged_chain_pos $this_out_lane_pos $OutboundLane $this_in_lane_pos $InboundLane --rpc-url http://127.0.0.1:9933)
