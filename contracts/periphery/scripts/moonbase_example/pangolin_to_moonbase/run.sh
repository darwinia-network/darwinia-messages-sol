#!/bin/zsh

# on pangolin, remote call `callee.add(2)`
if [ $# -lt 2 ]
then
  echo "Usage: run.sh <caller-contract-address> <callee-contract-address>"
  return
fi
local caller=$1
local callee=$2
local txhash="$(node ./scripts/moonbase_example/pangolin_to_moonbase/remote_add.js $caller $callee)"
echo "call from pangolin to moonbase: $txhash"
