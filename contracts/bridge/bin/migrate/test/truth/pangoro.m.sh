#!/usr/bin/env bash

set -e

unset TARGET_CHAIN
unset NETWORK_NAME
unset ETH_RPC_URL
export NETWORK_NAME=pangoro
export TARGET_CHAIN=goerli
# export ETH_RPC_URL=https://pangoro-rpc.darwinia.network
export ETH_RPC_URL=http://35.247.165.91:9933

. $(dirname $0)/base.sh

load_saddr() {
  jq -r ".[\"$TARGET_CHAIN\"].\"$1\"" "$PWD/bin/addr/$MODE/$NETWORK_NAME.json"
}

load_taddr() {
  jq -r ".[\"$NETWORK_NAME\"].\"$1\"" "$PWD/bin/addr/$MODE/$TARGET_CHAIN.json"
}

# beacon light client config
BLS_PRECOMPILE=0x0000000000000000000000000000000000000800
GENESIS_VALIDATORS_ROOT=0x043db0d9a83813551ee2f33450d23797757d430911a9320530ad8a0eabc43efb

HelixDaoMultisig=0x43d6711EB86C852Ec1E04af55C52a0dd51b2C743
OLD_BEACON_LC=$(load_saddr "BeaconLightClient")
EthereumStorageVerifier=$(load_saddr "EthereumStorageVerifier")

BeaconLightClientMigrator=$(dapp create src/migrate/BeaconLightClientMigrator.sol:BeaconLightClientMigrator \
  $HelixDaoMultisig \
  $OLD_BEACON_LC \
  $EthereumStorageVerifier \
  $BLS_PRECOMPILE \
  $GENESIS_VALIDATORS_ROOT)

save_contract "BeaconLightClientMigrator" "$BeaconLightClientMigrator"

data=$(seth calldata "changeSetter(address)" $BeaconLightClientMigrator)
seth send $HelixDaoMultisig "submitTransaction(address,uint,bytes)" $EthereumStorageVerifier 0 $data
seth send $BeaconLightClientMigrator "migrate()"

BeaconLightClient=$(seth call $BeaconLightClientMigrator "new_beacon_lc()(address)")
save_contract "BeaconLightClient" "$BeaconLightClient"

ExecutionLayer=$(seth call $BeaconLightClientMigrator "new_execution_layer()(address)")
save_contract "ExecutionLayer" "$ExecutionLayer"
