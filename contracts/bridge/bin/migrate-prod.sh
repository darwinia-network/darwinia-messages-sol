#!/usr/bin/env bash

set -eo pipefail

export MODE=prod

# . $(dirname $0)/migrate/prod/fee/darwinia.sh
# . $(dirname $0)/migrate/prod/fee/ethlive.sh
. $(dirname $0)/migrate/prod/truth/darwinia2.sh
