#!/usr/bin/env bash

set -eo pipefail

. $(dirname $0)/env.sh
. $(dirname $0)/color.sh
. $(dirname $0)/load.sh

# Call as `ETH_FROM=0x... ETH_RPC_URL=<url> deploy ContractName arg1 arg2 arg3`
# (or omit the env vars if you have already set them)
deploy() {
	NAME=$1
	ARGS=${@:2}

	# find file path
	CONTRACT_PATH=$(find ./$SRC_DIT -name $NAME.f.sol)
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

deploy_v2() {
  NAME=$1
  ARGS=${@:2}

  # find file path
  CONTRACT_PATH=$(find ./$SRC_DIT -name $NAME.sol)
  CONTRACT_PATH=${CONTRACT_PATH:2}

  # select the filename and the contract in it
  PATTERN=".contracts[\"$CONTRACT_PATH\"].$NAME"

  # get the constructor's signature
  ABI=$(jq -r "$PATTERN.abi" $OUT_DIR/dapp.sol.json)
  SIG=$(echo "$ABI" | seth --abi-constructor)

  FUNCHASH=$(seth keccak "$SIG")
  FUNCSIG=${FUNCHASH:2:8}

  # get the bytecode from the compiled file
  BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" $OUT_DIR/dapp.sol.json)

  # estimate gas
  GAS=$(seth estimate --from "$ETH_FROM" --create "$BYTECODE" "$FUNCSIG$ARGS" --rpc-url "$ETH_RPC_URL")

  # deploy
  ADDRESS=$(set -x; seth send --from "$ETH_FROM" --create "$BYTECODE" "$FUNCSIG$ARGS" -- --gas "$GAS" --rpc-url "$ETH_RPC_URL")

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
  if [[ -z ${TARGET_CHAIN} ]]; then
      result=$(cat "$ADDRESSES_FILE" | jq -r ". + {\"$1\": \"$2\"}")
  else
      result=$(cat "$ADDRESSES_FILE" | jq -r ".\"$TARGET_CHAIN\" += {\"$1\": \"$2\" }")
  fi
	printf %s "$result" >"$ADDRESSES_FILE"
}

estimate_gas() {
	NAME=$1
	ARGS=${@:2}
	# select the filename and the contract in it
	PATTERN=".contracts[\"$SRC_DIT/$NAME.sol\"].$NAME"

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
	PATTERN=".contracts[\"$SRC_DIT/$NAME.sol\"].$NAME"

	# get the bytecode from the compiled file
	BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" $OUT_DIR/dapp.sol.json)
	length=$(echo "$BYTECODE" | wc -m)
	echo $(($length / 2))
}
