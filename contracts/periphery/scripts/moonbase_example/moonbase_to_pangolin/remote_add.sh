#!/bin/zsh

# on moonbase, remote call `callee.add(2)`
if [ $# -lt 2 ]
then
  echo "Usage: run.sh <caller-contract-address> <callee-contract-address>"
  return
fi
local caller=$1
local callee=$2
local txhash="$(node ./scripts/moonbase_example/moonbase_to_pangolin/remote_add.js $caller $callee)"
echo "call from moonbase to pangolin: $txhash"
