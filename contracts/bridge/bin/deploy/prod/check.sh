#!/usr/bin/env bash

set -eo pipefail

export Chain0=darwinia
export Chain1=ethereum

# 0
(from=$Chain0 to=$Chain1 \
  dao=0xB29DA7C1b1514AB342afbE6AB915252Ad3f87E4d \
. $(dirname $0)/deploy/check-darwinia.sh)

(from=$Chain1 to=$Chain0 \
  dao=0xFfD0a972E371B8cFE34b8C9176CE77C0fF8D43e1 \
. $(dirname $0)/deploy/check-ethereum.sh)
