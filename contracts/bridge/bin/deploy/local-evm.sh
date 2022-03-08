#!/usr/bin/env bash

set -eo pipefail

export NETWORK_NAME=local-evm
export ETH_RPC_URL=${TEST_LOCAL_EVM_RPC:-http://127.0.0.1:8545}
export ETH_FROM=${TEST_LOCAL_EVM_FROM:-$(seth ls --keystore $TMPDIR/8545/keystore | cut -f1)}
export ETH_RPC_ACCOUNTS=true

# import the deployment helpers
. $(dirname $0)/common.sh

# bsctest to pangolin bridge config
this_chain_pos=1
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=0
bridged_in_lane_pos=1
bridged_out_lane_pos=0

# fee market config
FEEMARKET_VAULT=0x0000000000000000000000000000000000000000
COLLATERAL_PERORDER=$(seth --to-wei 1 ether)
ASSIGNED_RELAYERS_NUMBER=3
SLASH_TIME=86400
RELAY_TIME=86400

FeeMarket=$(deploy FeeMarket $FEEMARKET_VAULT $COLLATERAL_PERORDER $ASSIGNED_RELAYERS_NUMBER $SLASH_TIME $RELAY_TIME)

# darwinia beefy light client config
# Pangolin
NETWORK=0x50616e676f6c696e000000000000000000000000000000000000000000000000
BEEFY_SLASH_VALUT=0x0000000000000000000000000000000000000000
BEEFY_VALIDATOR_SET_ID=0
BEEFY_VALIDATOR_SET_LEN=4
BEEFY_VALIDATOR_SET_ROOT=0xa1ce8df8151796ab60157e0c6075a3a4cc170927b1b1fc0f33bde0e274e8f398
DarwiniaLightClient=$(deploy DarwiniaLightClient $NETWORK $BEEFY_SLASH_VALUT $BEEFY_VALIDATOR_SET_ID $BEEFY_VALIDATOR_SET_LEN $BEEFY_VALIDATOR_SET_ROOT)

OutboundLane=$(deploy OutboundLane $DarwiniaLightClient $this_chain_pos $this_out_lane_pos $bridged_chain_pos $bridged_in_lane_pos 1 0 0)
InboundLane=$(deploy InboundLane $DarwiniaLightClient $this_chain_pos $this_in_lane_pos $bridged_chain_pos $bridged_out_lane_pos 0 0)

seth send -F $ETH_FROM $OutboundLane "setFeeMarket(address)" $FeeMarket
seth send -F $ETH_FROM $FeeMarket "setOutbound(address,uint)" $OutboundLane 1

BSCLightClient=$(jq -r ".BSCLightClient" "$PWD/bin/addr/local-dvm.json")
(set -x; seth send -F 0x6Be02d1d3665660d22FF9624b7BE0551ee1Ac91b $BSCLightClient "registry(uint32,uint32,address,uint32,address)" $bridged_chain_pos $this_out_lane_pos $OutboundLane $this_in_lane_pos $InboundLane --rpc-url http://192.168.2.100:10033)

amount=$(seth --to-wei 1000 ether)
seth send -F $ETH_FROM -V $amount 0x3DFe30fb7b46b99e234Ed0F725B5304257F78992
seth send -F $ETH_FROM -V $amount 0xB3c5310Dcf15A852b81d428b8B6D5Fb684300DF9
seth send -F $ETH_FROM -V $amount 0xf4F07AAe298E149b902993B4300caB06D655f430

seth send -F $ETH_FROM $OutboundLane "rely(address)" 0x3DFe30fb7b46b99e234Ed0F725B5304257F78992
