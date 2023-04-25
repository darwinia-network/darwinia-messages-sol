#!/usr/bin/env bash

set -eo pipefail

export Chain0=darwinia
export Chain1=ethereum

# 0
(from=$Chain0 to=$Chain1 \
  dao=0xBd1a110ec476b4775c43905000288881367B1a88 \
. $(dirname $0)/deploy/check-darwinia.sh)

(from=$Chain1 to=$Chain0 \
  dao=0x4710573B853fDD3561cb4F60EC9394f0155d5105 \
. $(dirname $0)/deploy/check-ethereum.sh)
