#!/usr/bin/env bash

set -eo pipefail

export NETWORK_NAME=dvm
export TARGET_CHAIN=evm-eth2

. $(dirname $0)/base.sh

set -x
