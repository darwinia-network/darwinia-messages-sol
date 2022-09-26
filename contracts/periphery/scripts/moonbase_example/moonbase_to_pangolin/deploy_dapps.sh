#!/bin/zsh

# deploy callee and caller
if [ $# -lt 1 ]
then
  echo "Usage: deploy.sh <moonbase-endpoint-contract-address>"
  return
fi
local moonbase_endpoint=$1
local callee="$(node ./scripts/moonbase_example/moonbase_to_pangolin/deploy_callee_to_pangolin.js)"
echo "callee deployed on pangolin: $callee"
local caller="$(node ./scripts/moonbase_example/moonbase_to_pangolin/deploy_caller_to_moonbase.js $moonbase_endpoint)"
echo "caller deployed on moonbase: $caller"
