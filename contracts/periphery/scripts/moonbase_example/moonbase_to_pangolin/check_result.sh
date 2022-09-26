#!/bin/zsh

# on pangolin, get `callee.sum`
if [ $# -lt 1 ]
then
  echo "Usage: check_result.sh <callee-contract-address>"
  return
fi
local callee=$1
node ./scripts/moonbase_example/moonbase_to_pangolin/check_result.js $callee