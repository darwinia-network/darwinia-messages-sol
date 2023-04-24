#!/usr/bin/env bash

set -eo pipefail

Chain0=darwinia
Chain1=ethereum

# 0
(from=$Chain0 to=$Chain1 \
. $(dirname $0)/deploy/darwinia.sh)

(from=$Chain1 to=$Chain0 \
. $(dirname $0)/deploy/ethereum.sh)

# auth
(. $(dirname $0)/deploy/prod/auth.sh)
