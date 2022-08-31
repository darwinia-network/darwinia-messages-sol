#!/usr/bin/env bash

set -e

export MODE=test
export NETWORK_NAME=${1?}

. $(dirname $0)/verify/test/${NETWORK_NAME}.sh
