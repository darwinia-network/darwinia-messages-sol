In `contracts/periphery` dir:

1. deploy endpoints
   ```
   ./scripts/moonbase_example/deploy.sh
   ```
2.1. moonbase > pangolin
   ```
   ./scripts/moonbase_example/moonbase_to_pangolin/deploy.sh <moonbase-endpoint-contract-address>
   ./scripts/moonbase_example/moonbase_to_pangolin/run.sh <caller-contract-address> <callee-contract-address>
   ```
2.2. pangolin > moonbase
   ```
   ./scripts/moonbase_example/pangolin_to_moonbase/deploy.sh <pangolin-endpoint-contract-address>
   ./scripts/moonbase_example/pangolin_to_moonbase/run.sh <caller-contract-address> <callee-contract-address>
   ```
