#!/usr/bin/env bash

set -eo pipefail

export Chain0=pangolin
export Chain1=goerli
export Chain2=arbitest

# 0
(from=$Chain0 to=$Chain1 \
  dao=$ETH_FROM \
. $(dirname $0)/deploy/check-darwinia.sh)
(from=$Chain0 to=$Chain2 \
  dao=$ETH_FROM \
. $(dirname $0)/deploy/check-darwinia2.sh)

# 1
(from=$Chain1 to=$Chain0 \
  dao=$ETH_FROM \
. $(dirname $0)/deploy/check-ethereum.sh)

# 2
(from=$Chain2 to=$Chain0 \
  dao=$ETH_FROM \
. $(dirname $0)/deploy/check-arbitrum.sh)
