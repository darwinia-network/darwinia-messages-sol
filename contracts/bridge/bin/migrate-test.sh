#!/usr/bin/env bash

set -eo pipefail

export MODE=test
. $(dirname $0)/migrate/test/msg/pangoro-1.sh
. $(dirname $0)/migrate/test/msg/pangoro-2.sh
. $(dirname $0)/migrate/test/msg/goerli.sh
. $(dirname $0)/migrate/test/msg/bsctest.sh
