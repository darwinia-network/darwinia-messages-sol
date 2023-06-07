#!/usr/bin/env bash

set -eo pipefail

export Chain0=pangolin
export Chain1=goerli
export Chain2=arbitest

. $(dirname $0)/nonce.sh

# 0
(from=$Chain0 to=$Chain1 \
. $(dirname $0)/deploy/darwinia.sh)
(from=$Chain0 to=$Chain2 \
. $(dirname $0)/deploy/darwinia2.sh)

# 1
(from=$Chain1 to=$Chain0 \
. $(dirname $0)/deploy/ethereum.sh)

# 2
(from=$Chain2 to=$Chain0 \
. $(dirname $0)/deploy/arbitrum.sh)
