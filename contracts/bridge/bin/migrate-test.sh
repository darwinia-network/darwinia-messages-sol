#!/usr/bin/env bash

set -eo pipefail

export MODE=test

. $(dirname $0)/migrate/test/truth/pangoro.sh
