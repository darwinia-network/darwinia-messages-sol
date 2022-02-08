#!/usr/bin/env bash

set -eo pipefail

export NETWORK_NAME=local-dvm
. $(dirname $0)/base.sh

set -x
load-addresses
