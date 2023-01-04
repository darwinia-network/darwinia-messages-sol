#!/usr/bin/env bash

set -e

export MODE=${1?}

. $(dirname $0)/verify/${MODE}/verify.sh
