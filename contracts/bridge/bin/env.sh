#!/usr/bin/env bash

set -eo pipefail

# All contracts are output to `bin/addr/{chain}/addresses.json` by default
mode=${MODE?}
root_dir=$(realpath .)
network_name=${SOURCE_CHAIN?}
ADDRESSES_FILE="${root_dir}/bin/addr/${mode}/${network_name}.json"
CONFIG_FILE="${root_dir}/bin/conf/${mode}/${network_name}.json"
OUT_DIR=$root_dir/out
SRC_DIR=${DAPP_SRC-flat}

# ensure ETH_FROM is set and give a meaningful error message
if [[ -z ${ETH_FROM} ]]; then
	echo "ETH_FROM not found, please set it and re-run the last command."
	exit 1
fi

# Make sure address is checksummed
if [ "$ETH_FROM" != "$(seth --to-checksum-address "$ETH_FROM")" ]; then
	echo "ETH_FROM not checksummed, please format it with 'seth --to-checksum-address <address>'"
	exit 1
fi
