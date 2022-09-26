#!/bin/zsh

# deploy endpoints
local moonbase_endpoint="$(node ./scripts/moonbase_example/deploy_moonbase_endpoint.js)"
echo "MOONBASE_ENDPOINT DEPLOYED     : $moonbase_endpoint"
local pangolin_endpoint="$(node ./scripts/moonbase_example/deploy_pangolin_endpoint.js)"
echo "PANGOLIN_ENDPOINT DEPLOYED     : $pangolin_endpoint"
echo "-------------------------------------------------------------------------------------------------------"

# link endpoints
node ./scripts/moonbase_example/set_remote_endpoint_on_moonbase.js $moonbase_endpoint $pangolin_endpoint
node ./scripts/moonbase_example/set_remote_endpoint_on_pangolin.js $pangolin_endpoint $moonbase_endpoint
echo "ENDPOINTS LINKED"
