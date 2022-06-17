#!/usr/bin/env bash

set -e

export MODE=test
. $(dirname $0)/deploy/test/pangoro.sh
. $(dirname $0)/deploy/test/ropsten.sh
. $(dirname $0)/deploy/test/bsctest.sh
