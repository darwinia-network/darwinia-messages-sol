#!/usr/bin/env bash

set -e

export MODE=test

export ETH_GAS_PRICE=10000000000
. $(dirname $0)/deploy/test/pangoro.sh
export ETH_GAS_PRICE=2000000000
. $(dirname $0)/deploy/test/goerli.sh
# export ETH_GAS_PRICE=10000000000
# . $(dirname $0)/deploy/test/bsctest.sh
