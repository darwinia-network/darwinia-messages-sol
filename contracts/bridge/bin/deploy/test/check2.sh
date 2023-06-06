#!/usr/bin/env bash

set -eo pipefail

export Chain0=pangolin
export Chain1=arbitest

# 0
(from=$Chain0 to=$Chain1 \
  dao=$ETH_FROM \
. $(dirname $0)/deploy/check-darwinia2.sh)

(from=$Chain1 to=$Chain0 \
  dao=$ETH_FROM \
. $(dirname $0)/deploy/check-arbitrum.sh)
