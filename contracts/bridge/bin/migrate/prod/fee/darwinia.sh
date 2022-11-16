#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=darwinia
export TARGET_CHAIN=ethlive
export ETH_RPC_URL=https://rpc.darwinia.network

echo "ETH_FROM: ${ETH_FROM}"

. $(dirname $0)/base.sh

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
