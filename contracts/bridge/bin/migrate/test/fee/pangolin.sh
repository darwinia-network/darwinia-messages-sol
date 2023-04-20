#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
unset SETH_CHAIN
export NETWORK_NAME=pangolin
export TARGET_CHAIN=goerli
export SETH_CHAIN=pangolin

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
FEEMARKET_VAULT=$(load_conf ".FeeMarket.vault")
COLLATERAL_PERORDER=$(load_conf ".FeeMarket.collateral_perorder")
ASSIGNED_RELAYERS_NUMBER=$(load_conf ".FeeMarket.assigned_relayers_number")
SLASH_TIME=$(load_conf ".FeeMarket.slash_time")
RELAY_TIME=$(load_conf ".FeeMarket.relay_time")
# 0.01 : 2000
PRICE_RATIO=$(load_conf ".FeeMarket.price_ratio")
DUTY_RATIO=$(load_conf ".FeeMarket.duty_ratio")

FeeMarket=$(deploy FeeMarket \
  $FEEMARKET_VAULT \
  $COLLATERAL_PERORDER \
  $ASSIGNED_RELAYERS_NUMBER \
  $SLASH_TIME $RELAY_TIME \
  $PRICE_RATIO $DUTY_RATIO)

upgrade $BridgeProxyAdmin $FeeMarket $FeeMarketProxy
