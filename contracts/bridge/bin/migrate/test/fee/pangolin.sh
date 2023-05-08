#!/usr/bin/env bash

set -e

unset SOURCE_CHAIN
unset TARGET_CHAIN
unset ETH_RPC_URL
export SOURCE_CHAIN=pangolin
export TARGET_CHAIN=goerli

. $(dirname $0)/base.sh

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
