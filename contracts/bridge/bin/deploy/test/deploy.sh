#!/usr/bin/env bash

set -e

Chain0=pangolin
Chain1=goerli

# 0
(from=$Chain0 to=$Chain1 \
. $(dirname $0)/deploy/darwinia.sh)

(from=$Chain1 to=$Chain0
. $(dirname $0)/deploy/test/goerli.sh)
