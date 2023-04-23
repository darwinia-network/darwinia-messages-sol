#!/usr/bin/env bash

set -e

Chain0=darwinia
Chain1=ethereum

unset ETH_FROM

# 0
(from=$Chain0 to=$Chain1 \
 ETH_FROM=0x7aE77149ed38c5dD313e9069d790Ce7085caf0A6 \
. $(dirname $0)/deploy/darwinia.sh)

(from=$Chain1 to=$Chain0 \
 ETH_FROM=0xa4FA5429544B225985F8438F2E013A9CCE7102f2 \
. $(dirname $0)/deploy/ethereum.sh)

# auth
(. $(dirname $0)/deploy/prod/auth.sh)
