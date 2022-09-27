#!/usr/bin/env bash

set -e

export MODE=prod

if [[ -z ${INFURA_KEY} ]]; then
	echo "INFURA_KEY not found, please set it and re-run the last command."
	exit 1
fi
# export ETH_GAS_PRICE=1300000000
# . $(dirname $0)/deploy/prod/darwinia.sh
# export ETH_GAS_PRICE=2000000000
. $(dirname $0)/deploy/prod/ethlive.sh
