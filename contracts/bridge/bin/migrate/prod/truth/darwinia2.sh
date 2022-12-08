#!/usr/bin/env bash

set -ex

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=darwinia
export TARGET_CHAIN=ethlive
export ETH_RPC_URL=https://rpc.darwinia.network

echo "ETH_FROM: ${ETH_FROM}"

. $(dirname $0)/base.sh

load_saddr() {
  jq -r ".[\"$TARGET_CHAIN\"].\"$1\"" "$PWD/bin/addr/$MODE/$NETWORK_NAME.json"
}

load_taddr() {
  jq -r ".[\"$NETWORK_NAME\"].\"$1\"" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json"
}

HelixDaoMultisig=0xBd1a110ec476b4775c43905000288881367B1a88
EthereumStorageVerifier=$(load_saddr "EthereumStorageVerifier")
ExecutionLayer=$(load_saddr "ExecutionLayer")

data=$(seth calldata "changeLightClient(address)" $ExecutionLayer)
seth call -F $HelixDaoMultisig $EthereumStorageVerifier $data
seth send -F $ETH_FROM $HelixDaoMultisig "submitTransaction(address,uint,bytes)" $EthereumStorageVerifier 0 $data
count=$(seth call $HelixDaoMultisig "transactionCount()(uint)")
seth call $HelixDaoMultisig "transactions(uint)(address,uint,bytes,bool)" $(( $count - 1 ))
