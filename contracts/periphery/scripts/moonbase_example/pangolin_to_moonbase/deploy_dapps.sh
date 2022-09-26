#!/bin/zsh

# deploy caller and callee
if [ $# -lt 1 ]
then
  echo "Usage: deploy.sh <pangolin-endpoint-contract-address>"
  return
fi
local pangolin_endpoint=$1
local caller="$(node ./scripts/moonbase_example/pangolin_to_moonbase/deploy_caller_to_pangolin.js $pangolin_endpoint)"
echo "caller deployed on pangolin: $caller"
local callee="$(node ./scripts/moonbase_example/pangolin_to_moonbase/deploy_callee_to_moonbase.js)"
echo "callee deployed on moonbase: $callee"

