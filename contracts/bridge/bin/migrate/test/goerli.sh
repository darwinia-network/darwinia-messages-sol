#!/usr/bin/env bash

set -e

export NETWORK_NAME=goerli
export TARGET_CHAIN=pangoro
export ETH_RPC_URL=https://rpc.ankr.com/eth_goerli

. $(dirname $0)/base.sh

set -x
load-addresses
