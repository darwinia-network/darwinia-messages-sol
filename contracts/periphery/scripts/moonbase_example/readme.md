In `contracts/periphery` dir:

1. deploy endpoints
   ```
   ./scripts/moonbase_example/deploy_endpoints.sh
   ```
2.1. moonbase > pangolin
   ```
   ./scripts/moonbase_example/moonbase_to_pangolin/deploy_dapps.sh <moonbase-endpoint-contract-address>
   ./scripts/moonbase_example/moonbase_to_pangolin/remote_add.sh <caller-contract-address> <callee-contract-address>
   ```
2.2. pangolin > moonbase
   ```
   ./scripts/moonbase_example/pangolin_to_moonbase/deploy_dapps.sh <pangolin-endpoint-contract-address>
   ./scripts/moonbase_example/pangolin_to_moonbase/remote_add.sh <caller-contract-address> <callee-contract-address>
   ```
