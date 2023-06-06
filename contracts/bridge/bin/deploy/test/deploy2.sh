#!/usr/bin/env bash

set -eo pipefail

export Chain0=pangolin
export Chain2=arbitest

. $(dirname $0)/nonce.sh

# 0
(from=$Chain0 to=$Chain2 \
. $(dirname $0)/deploy/darwinia2.sh)

# 1
(from=$Chain2 to=$Chain0 \
. $(dirname $0)/deploy/arbitrum.sh)
