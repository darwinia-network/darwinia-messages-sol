#!/usr/bin/env bash

set -e

oops() {
  echo >&2 "${0##*/}: error:" "$@"
  exit 1
}

have() { command -v "$1" >/dev/null; }

start_geth() {
  echo "Starting geth"
  { have dapp && have seth; } && {
    . $(dirname $0)/run-evm-testnet.sh
  }
}

strat_drml() {
  echo "Starting drml"
  { have drml; } || oops "you need to install drml before running this script"
  . $(dirname $0)/run-dvm-testnet.sh
}

compile_contracts() {
  echo "Compiling contracts"
  make
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

start_geth
strat_drml

compile_contracts
deploy_dvm_contracts
deploy_evm_contracts

echo "Testnet has been initialized"
