#!/usr/bin/env bash

set -e

output_dir=$(mktemp -d)


start_geth() {
  dapp testnet
}

strat_drml() {
  drml \
    --chain=template-dev \
    --validator \
    --execution=Native \
    --no-telemetry \
    --no-prometheus \
    --sealing=Manual \
    --no-grandpa \
    --force-authoring \
    -levm=debug \
    --port=30333 \
    --rpc-port=9933 \
    --ws-port=9944 \
    --tmp
}

# deploy_evm_contracts() {
#   echo "Deploying evm contracts"
#   (
#     npx hardhat deploy --network localhost:evm --reset --export "$output_dir/evm_contracts.json"
#   )
#   echo "Exported contract artifacts: $output_dir/evm_contracts.json"
# }

# deploy_dvm_contracts() {
#   echo "Deploying dvm contracts"
#   (
#     npx hardhat deploy --network localhost:evm --reset --export "$output_dir/dvm_contracts.json"
#   )
#   echo "Exported contract artifacts: $output_dir/dvm_contracts.json"
# }
