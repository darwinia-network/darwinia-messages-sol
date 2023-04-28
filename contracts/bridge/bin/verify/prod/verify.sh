#!/usr/bin/env bash

set -eo pipefail

export Chain0=darwinia
export Chain1=ethereum

(from=$Chain0 to=$Chain1 \
. $(dirname $0)/verify/darwinia.sh)

(from=$Chain1 to=$Chain0 \
. $(dirname $0)/verify/ethereum.sh)
