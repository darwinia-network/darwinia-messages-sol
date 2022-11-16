#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=ethlive
export ETH_RPC_URL=https://mainnet.infura.io/$INFURA_KEY

echo "ETH_FROM: ${ETH_FROM}"

. $(dirname $0)/base.sh

# fee market config
# https://etherscan.io/chart/gasprice
# 300000 wei * 100 gwei = 0.03 ether or 6000 RING
COLLATERAL_PERORDER=$(seth --to-wei 0.03 ether)
RELAY_TIME=10800
SLASH_TIME=10800
# price 2000 : 0.01
# 1000 : 999000
PRICE_RATIO=1000
DUTY_RATIO=30

SimpleFeeMarket=$(deploy SimpleFeeMarket \
  $COLLATERAL_PERORDER \
  $SLASH_TIME $RELAY_TIME \
  $PRICE_RATIO $DUTY_RATIO)
