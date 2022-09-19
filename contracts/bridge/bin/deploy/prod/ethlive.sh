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

# fee market config
# https://etherscan.io/chart/gasprice
# 300000 wei * 10 * 20 gwei = 0.06 ether or 12000 RING
COLLATERAL_PERORDER=$(seth --to-wei 0.06 ether)
RELAY_TIME=10800
SLASH_TIME=10800
# price 2000 : 0.01
# 1000 : 999000
PRICE_RATIO=1000

SimpleFeeMarket=$(deploy SimpleFeeMarket $COLLATERAL_PERORDER $SLASH_TIME $RELAY_TIME $PRICE_RATIO)

sig="initialize()"
data=$(seth calldata $sig)
FeeMarketProxy=$(deploy FeeMarketProxy \
  $SimpleFeeMarket \
  $BridgeProxyAdmin \
  $data)

# darwinia ecdsa-authority light client config
# seth keccak "46Darwinia::ecdsa-authority"
DOMAIN_SEPARATOR=0xf8a76f5ceeff36d74ff99c4efc0077bcc334721f17d1d5f17cfca78455967e1e
relayers=[0x953d65e6054b7eb1629f996238c0aa9b4e2dbfe9,0x7c9b3d4cfc78c681b7460acde2801452aef073a9,0x717c38fd5fdecb1b105a470f861b33a6b0f9f7b8,0x3e25247cff03f99a7d83b28f207112234fee73a6,0x2EaBE5C6818731E282B80De1a03f8190426e0Dd9]
threshold=3
nonce=0

POSALightClient=$(deploy POSALightClient $DOMAIN_SEPARATOR \
  $relayers \
  $threshold \
  $nonce)

DarwiniaMessageVerifier=$(deploy DarwiniaMessageVerifier $POSALightClient)

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
