#!/usr/bin/env bash

set -eo pipefail

export MODE=${1?}

. $(dirname $0)/deploy/${MODE}/deploy.sh
