#!/usr/bin/env bash

set -eo pipefail

export Chain0=pangolin
export Chain1=goerli
export Chain2=arbitest

. $(dirname $0)/nonce.sh

(from=$Chain0 to=$Chain2 \
. $(dirname $0)/migrate/test/truth/pangolin.sh)
