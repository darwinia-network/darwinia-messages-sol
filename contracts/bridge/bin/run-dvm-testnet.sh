#!/usr/bin/env bash

set -eo pipefail

# clean up
trap 'killall drml' EXIT
trap "exit 1" SIGINT SIGTERM

# launch the testnet
  drml \
    --dev \
    --tmp &
# wait for it to launch (can't go <3s)
sleep 3

# set the RPC URL to the local testnet
export ETH_RPC_URL=http://127.0.0.1:9933

# get the created account (it's unlocked so we only need to set the address)
export ETH_FROM=0x6Be02d1d3665660d22FF9624b7BE0551ee1Ac91b
