#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=goerli
export TARGET_CHAIN=pangoro
export ETH_RPC_URL=https://rpc.ankr.com/eth_goerli

. $(dirname $0)/base.sh

load_saddr() {
  jq -r ".[\"$TARGET_CHAIN\"].\"$1\"" "$PWD/bin/addr/$MODE/$NETWORK_NAME.json"
}

load_staddr() {
  jq -r ".\"$1\"" "$PWD/bin/addr/$MODE/$NETWORK_NAME.json"
}

load_taddr() {
  jq -r ".[\"$NETWORK_NAME\"].\"$1\"" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json"
}

BridgeProxyAdmin=$(load_staddr "BridgeProxyAdmin")
FeeMarketProxy=$(load_saddr "FeeMarketProxy")

# fee market config
COLLATERAL_PERORDER=$(seth --to-wei 0.0001 ether)
SLASH_TIME=10800
RELAY_TIME=10800
# 300 : 0.01
PRICE_RATIO=1000
DUTY_RATIO=30

SimpleFeeMarket=$(deploy SimpleFeeMarket \
  $COLLATERAL_PERORDER \
  $SLASH_TIME $RELAY_TIME \
  $PRICE_RATIO $DUTY_RATIO)

upgrade $BridgeProxyAdmin $SimpleFeeMarket $FeeMarketProxy
