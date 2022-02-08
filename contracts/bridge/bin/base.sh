#!/usr/bin/env bash

set -eo pipefail

# All contracts are output to `bin/addr/{chain}/addresses.json` by default
network_name=${NETWORK_NAME?}
root_dir=$(realpath .)
ADDRESSES_FILE="${root_dir}/bin/addr/${network_name}.json"
CONFIG_FILE="${root_dir}/bin/conf/${network_name}.json"
OUT_DIR=$root_dir/out

ETH_RPC_URL=${ETH_RPC_URL:-http://localhost:8545}

# green log helper
GREEN='\033[0;32m'
NC='\033[0m' # No Color
log() {
	printf '%b\n' "${GREEN}${*}${NC}" >&2
	echo ""
}

# Coloured output helpers
if command -v tput >/dev/null 2>&1; then
	if [ $(($(tput colors 2>/dev/null))) -ge 8 ]; then
		# Enable colors
		TPUT_RESET="$(tput sgr 0)"
		TPUT_YELLOW="$(tput setaf 3)"
		TPUT_RED="$(tput setaf 1)"
		TPUT_BLUE="$(tput setaf 4)"
		TPUT_GREEN="$(tput setaf 2)"
		TPUT_WHITE="$(tput setaf 7)"
		TPUT_BOLD="$(tput bold)"
	fi
fi

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

# Call as `ETH_FROM=0x... ETH_RPC_URL=<url> deploy ContractName arg1 arg2 arg3`
# (or omit the env vars if you have already set them)
deploy() {
	NAME=$1
	ARGS=${@:2}

	# find file path
	CONTRACT_PATH=$(find ./src -name $NAME.sol)
	CONTRACT_PATH=${CONTRACT_PATH:2}

	# select the filename and the contract in it
	PATTERN=".contracts[\"$CONTRACT_PATH\"].$NAME"

	# get the constructor's signature
	ABI=$(jq -r "$PATTERN.abi" $OUT_DIR/dapp.sol.json)
	SIG=$(echo "$ABI" | seth --abi-constructor)

	# get the bytecode from the compiled file
	BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" $OUT_DIR/dapp.sol.json)

	# estimate gas
	GAS=$(seth estimate --create "$BYTECODE" "$SIG" $ARGS --rpc-url "$ETH_RPC_URL" --from "$ETH_FROM")

	# deploy
	ADDRESS=$(dapp create "$NAME" $ARGS -- --gas "$GAS" --rpc-url "$ETH_RPC_URL" --from "$ETH_FROM")

	# save the addrs to the json
	# TODO: It'd be nice if we could evolve this into a minimal versioning system
	# e.g. via commit / chainid etc.
	save_contract "$NAME" "$ADDRESS"

  log "$NAME deployed at" $ADDRESS

	echo "$ADDRESS"
}

# Call as `save_contract ContractName 0xYourAddress` to store the contract name
# & address to the addresses json file
save_contract() {
	# create an empty json if it does not exist
	if [[ ! -e $ADDRESSES_FILE ]]; then
		echo "{}" >"$ADDRESSES_FILE"
	fi
	result=$(cat "$ADDRESSES_FILE" | jq -r ". + {\"$1\": \"$2\"}")
	printf %s "$result" >"$ADDRESSES_FILE"
}

estimate_gas() {
	NAME=$1
	ARGS=${@:2}
	# select the filename and the contract in it
	PATTERN=".contracts[\"src/$NAME.sol\"].$NAME"

	# get the constructor's signature
	ABI=$(jq -r "$PATTERN.abi" $OUT_DIR/dapp.sol.json)
	SIG=$(echo "$ABI" | seth --abi-constructor)

	# get the bytecode from the compiled file
	BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" $OUT_DIR/dapp.sol.json)
	# estimate gas
	GAS=$(seth estimate --create "$BYTECODE" "$SIG" $ARGS --rpc-url "$ETH_RPC_URL" --from "$ETH_FROM")

	TXPRICE_RESPONSE=$(curl -sL https://api.txprice.com/v1)
	response=$(jq '.code' <<<"$TXPRICE_RESPONSE")
	if [[ $response != "200" ]]; then
		echo "Could not get gas information from ${TPUT_BOLD}txprice.com${TPUT_RESET}: https://api.txprice.com/v1"
		echo "response code: $response"
	else
		rapid=$(($(jq '.blockPrices[0].estimatedPrices[0].maxFeePerGas' <<<"$TXPRICE_RESPONSE")))
		fast=$(($(jq '.blockPrices[0].estimatedPrices[1].maxFeePerGas' <<<"$TXPRICE_RESPONSE")))
		standard=$(($(jq '.blockPrices[0].estimatedPrices[2].maxFeePerGas' <<<"$TXPRICE_RESPONSE")))
		slow=$(($(jq '.blockPrices[0].estimatedPrices[3].maxFeePerGas' <<<"$TXPRICE_RESPONSE")))
		basefee$(($(jq '.blockPrices[0].baseFeePerGas' <<<"$TXPRICE_RESPONSE")))
		echo "Gas prices from ${TPUT_BOLD}txprice.com${TPUT_RESET}: https://api.txprice.com/v1"
		echo " \
     ${TPUT_RED}Rapid: $rapid gwei ${TPUT_RESET} \n
     ${TPUT_YELLOW}Fast: $fast gwei \n
     ${TPUT_BLUE}Standard: $standard gwei \n
     ${TPUT_GREEN}Slow: $slow gwei${TPUT_RESET}" | column -t
		size=$(contract_size "$NAME")
		echo "Estimated Gas cost for deployment of $NAME: ${TPUT_BOLD}$GAS${TPUT_RESET} units of gas"
		echo "Contract Size: ${size} bytes"
		echo "Total cost for deployment:"
		rapid_cost=$(echo "scale=5; $GAS*$rapid" | bc)
		fast_cost=$(echo "scale=5; $GAS*$fast" | bc)
		standard_cost=$(echo "scale=5; $GAS*$standard" | bc)
		slow_cost=$(echo "scale=5; $GAS*$slow" | bc)
		echo " \
     ${TPUT_RED}Rapid: $rapid_cost ETH ${TPUT_RESET} \n
     ${TPUT_YELLOW}Fast: $fast_cost ETH \n
     ${TPUT_BLUE}Standard: $standard_cost ETH \n
     ${TPUT_GREEN}Slow: $slow_cost ETH ${TPUT_RESET}" | column -t
	fi
}

contract_size() {
	NAME=$1
	ARGS=${@:2}
	# select the filename and the contract in it
	PATTERN=".contracts[\"src/$NAME.sol\"].$NAME"

	# get the bytecode from the compiled file
	BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" $OUT_DIR/dapp.sol.json)
	length=$(echo "$BYTECODE" | wc -m)
	echo $(($length / 2))
}

load_conf() {
  if [ -z "$1" ]
    then
      echo "conf: Invalid key"
      exit 1
  fi
  local key; key=$1
  jq -r "${key}" "$CONFIG_FILE"
}

load-addresses() {
  path=${ADDRESSES_FILE:-$1}
  if [[ ! -e "$path" ]]; then
    echo "Addresses file not found: $path not found"
    exit 1
  fi
  echo $path
  local exports
  exports=$(cat $path | jq -r " . | \
    to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]")
  for e in $exports; do export "$e"; done
}
