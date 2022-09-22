#!/bin/zsh

# deploy endpoints
local moonbase_endpoint="$(node ./scripts/moonbase_example/deploy_moonbase_endpoint.js)"
echo "moonbase endpoint deployed: $moonbase_endpoint"
local pangolin_endpoint="$(node ./scripts/moonbase_example/deploy_pangolin_endpoint.js)"
echo "pangolin endpoint deployed: $pangolin_endpoint"

# link endpoints
node ./scripts/moonbase_example/set_remote_endpoint_on_moonbase.js $moonbase_endpoint $pangolin_endpoint
node ./scripts/moonbase_example/set_remote_endpoint_on_pangolin.js $pangolin_endpoint $moonbase_endpoint
echo "endpoints linked"
