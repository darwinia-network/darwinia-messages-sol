#!/usr/bin/env bash

set -eo pipefail

export Chain0=pangolin
export Chain1=goerli
export Chain2=arbitest

# 0
# (from=$Chain0 to=$Chain1 \
# . $(dirname $0)/verify/darwinia.sh)

# 1
# (from=$Chain1 to=$Chain0 \
# . $(dirname $0)/verify/ethereum.sh)

# 2
(from=$Chain2 to=$Chain0 \
. $(dirname $0)/verify/ethereum.sh)
