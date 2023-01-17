#!/usr/bin/env bash

set -eo pipefail

export MODULE=${1?}

. $(dirname $0)/circom/build/build.sh ${MODULE}
