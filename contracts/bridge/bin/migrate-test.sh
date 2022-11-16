#!/usr/bin/env bash

set -eo pipefail

export MODE=test

. $(dirname $0)/migrate/test/fee/pangoro-1.sh
. $(dirname $0)/migrate/test/fee/goerli.sh
