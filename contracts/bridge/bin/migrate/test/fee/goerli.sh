#!/usr/bin/env bash

set -e

unset SOURCE_CHAIN
unset TARGET_CHAIN
unset ETH_RPC_URL
export SOURCE_CHAIN=goerli
export TARGET_CHAIN=pangolin

. $(dirname $0)/base.sh

BridgeProxyAdmin=$(load_staddr "BridgeProxyAdmin")
FeeMarketProxy=$(load_saddr "FeeMarketProxy")

# fee market config
COLLATERAL_PERORDER=$(load_conf ".FeeMarket.collateral_perorder")
SLASH_TIME=$(load_conf ".FeeMarket.slash_time")
RELAY_TIME=$(load_conf ".FeeMarket.relay_time")
# 300 : 0.01
PRICE_RATIO=$(load_conf ".FeeMarket.price_ratio")
DUTY_RATIO=$(load_conf ".FeeMarket.duty_ratio")

SimpleFeeMarket=$(deploy SimpleFeeMarket \
  $COLLATERAL_PERORDER \
  $SLASH_TIME $RELAY_TIME \
  $PRICE_RATIO $DUTY_RATIO)

upgrade $BridgeProxyAdmin $SimpleFeeMarket $FeeMarketProxy
