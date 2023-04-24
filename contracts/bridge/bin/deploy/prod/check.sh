#!/usr/bin/env bash

set -eo pipefail

export Chain0=darwinia
export Chain1=ethereum

# 0
(from=$Chain0 to=$Chain1 \
  dao=$ETH_FROM \
. $(dirname $0)/deploy/check-darwinia.sh)

(from=$Chain1 to=$Chain0 \
  dao=$ETH_FROM \
. $(dirname $0)/deploy/check-ethereum.sh)
