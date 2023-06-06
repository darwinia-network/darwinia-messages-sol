#!/usr/bin/env bash

set -eo pipefail

export Chain0=pangolin
export Chain1=arbitest

. $(dirname $0)/nonce.sh

# 0
# (from=$Chain0 to=$Chain1 \
# . $(dirname $0)/deploy/darwinia2.sh)

# 1
(from=$Chain1 to=$Chain0 \
. $(dirname $0)/deploy/arbitrum.sh)
