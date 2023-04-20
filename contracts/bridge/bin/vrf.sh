#!/usr/bin/env bash

set -eo pipefail

. $(dirname $0)/env.sh

verify() {
  NAME=$1
  ADDR=$2
  ARGS=${@:3}

	# find file path
	CONTRACT_PATH=$(find ./$SRC_DIR -name $NAME.f.sol)
	CONTRACT_PATH=${CONTRACT_PATH:2}
	CONTRACT_PATH=$CONTRACT_PATH:$NAME

  cmd="dapp verify-contract"

  (set -x; $cmd $CONTRACT_PATH $ADDR $ARGS)
}
