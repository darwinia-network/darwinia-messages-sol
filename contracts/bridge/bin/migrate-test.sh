#!/usr/bin/env bash

set -eo pipefail

export MODE=test
. $(dirname $0)/migrate/test/goerli.sh
# . $(dirname $0)/migrate/test/bsctest.sh
