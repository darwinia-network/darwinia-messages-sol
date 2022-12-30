#!/usr/bin/env bash

set -eo pipefail

export MODE=local
. $(dirname $0)/migrate/local/dvm.sh
