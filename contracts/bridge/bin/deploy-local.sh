#!/usr/bin/env bash

set -e

export MODE=local
. $(dirname $0)/deploy/local/dvm.sh
. $(dirname $0)/deploy/local/evm.sh
