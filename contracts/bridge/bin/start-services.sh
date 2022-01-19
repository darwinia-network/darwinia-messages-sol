#!/usr/bin/env bash

set -e

output_dir=$(mktemp -d)


start_geth() {
  dapp testnet
}

strat_drml() {
  ./drml \
    --rpc-cors all \
    --allow-private-ipv4 \
    --port=30333 \
    --unsafe-rpc-external \
    --unsafe-ws-external \
    --rpc-methods=Unsafe \
    --rpc-port=9933 \
    --ws-port=9944 \
    -levm=debug \
    --dev \
    --tmp
}

deploy_evm_contracts() {
  echo "Deploying evm contracts"
  (
    make deploy network_name=local-evm
  )
}

deploy_dvm_contracts() {
  echo "Deploying dvm contracts"
  (
    make deploy network_name=local-dvm
  )
}
