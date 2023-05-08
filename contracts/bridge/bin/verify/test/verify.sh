#!/usr/bin/env bash

set -eo pipefail

export Chain0=pangolin
export Chain1=goerli

(from=$Chain0 to=$Chain1 \
. $(dirname $0)/verify/darwinia.sh)

(from=$Chain1 to=$Chain0 \
. $(dirname $0)/verify/ethereum.sh)
