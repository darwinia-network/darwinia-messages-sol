#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=ethlive
export ETH_RPC_URL=https://mainnet.infura.io/$INFURA_KEY
echo "ETH_FROM: ${ETH_FROM}"

# import the deployment helpers
. $(dirname $0)/common.sh

BridgeProxyAdmin=$(deploy BridgeProxyAdmin)

export TARGET_CHAIN=darwinia


# bsctest to pangoro bridge config
this_chain_pos=1
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=0
bridged_in_lane_pos=1
bridged_out_lane_pos=0

# TODO: fee market config
COLLATERAL_PERORDER=$(seth --to-wei 0.0001 ether)
SLASH_TIME=86400
RELAY_TIME=86400
# 300 : 0.01
PRICE_RATIO=100

SimpleFeeMarket=$(deploy SimpleFeeMarket $COLLATERAL_PERORDER $SLASH_TIME $RELAY_TIME $PRICE_RATIO)

sig="initialize()"
data=$(seth calldata $sig)
FeeMarketProxy=$(deploy FeeMarketProxy \
  $SimpleFeeMarket \
  $BridgeProxyAdmin \
  $data)

# TODO: darwinia beefy light client config
# seth keccak "46Darwinia::ecdsa-authority"
DOMAIN_SEPARATOR=0xf8a76f5ceeff36d74ff99c4efc0077bcc334721f17d1d5f17cfca78455967e1e
relayers=[]
threshold=
nonce=0

POSALightClient=$(deploy POSALightClient $DOMAIN_SEPARATOR)

sig="initialize(address[],uint256,uint256)"
data=$(seth calldata $sig \
  $relayers \
  $threshold \
  $nonce)
DarwiniaLightClientProxy=$(deploy DarwiniaLightClientProxy \
  $POSALightClient \
  $BridgeProxyAdmin \
  $data)

DarwiniaMessageVerifier=$(deploy DarwiniaMessageVerifier $DarwiniaLightClientProxy)

OutboundLane=$(deploy OutboundLane \
  $DarwiniaMessageVerifier \
  $FeeMarketProxy \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

InboundLane=$(deploy InboundLane \
  $DarwiniaMessageVerifier \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $OutboundLane 1

EthereumStorageVerifier=$(jq -r ".[\"$NETWORK_NAME\"].EthereumStorageVerifier" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json")
(set -x; seth send -F $ETH_FROM $EthereumStorageVerifier "registry(uint32,uint32,address,uint32,address)" \
  $bridged_chain_pos $this_out_lane_pos $OutboundLane $this_in_lane_pos $InboundLane --rpc-url https://rpc.darwinia.network)
