#!/usr/bin/env bash

set -e

export MODE=${1?}

. $(dirname $0)/stats/${MODE}/stats.sh
