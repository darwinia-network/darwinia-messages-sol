#!/usr/bin/env bash

set -eo pipefail

. $(dirname $0)/env.sh
. $(dirname $0)/color.sh
. $(dirname $0)/load.sh
. $(dirname $0)/vrf.sh
. $(dirname $0)/eta-gas.sh

# Call as `ETH_FROM=0x... SOURCE_CHAIN=<chain> deploy ContractName arg1 arg2 arg3`
# (or omit the env vars if you have already set them)
deploy() {
  NAME=$1
  ARGS=${@:2}

	# find file path
	CONTRACT_PATH=$(find ./$SRC_DIR -name $NAME.f.sol)
	CONTRACT_PATH=${CONTRACT_PATH:2}

  # select the filename and the contract in it
  PATTERN=".contracts[\"$CONTRACT_PATH\"].$NAME"

  # get the constructor's signature
  ABI=$(jq -r "$PATTERN.abi" $OUT_DIR/dapp.sol.json)
  SIG=$(echo "$ABI" | seth --abi-constructor)

  # get the bytecode from the compiled file
  BYTECODE=0x$(jq -r "$PATTERN.evm.bytecode.object" $OUT_DIR/dapp.sol.json)

  # estimate gas
  GAS=$(seth estimate --create "$BYTECODE" "$SIG" $ARGS --chain "$SOURCE_CHAIN" --from "$ETH_FROM")

  # deploy
  ADDRESS=$(dapp create "$NAME" $ARGS -- --gas "$GAS" --chain "$SOURCE_CHAIN" --from "$ETH_FROM")

  # save the addrs to the json
  # TODO: It'd be nice if we could evolve this into a minimal versioning system
  # e.g. via commit / chainid etc.
  save_contract "$NAME" "$ADDRESS"

  log "$NAME deployed at" $ADDRESS

  echo "$ADDRESS"
}

upgrade() {
  local admin; admin=$1
  local newImp; newImp=$2
  local proxy; proxy=$3
  seth send "$admin" "upgrade(address,address)" "$proxy" "$newImp" --chain "$SOURCE_CHAIN" --from "$ETH_FROM"
  if test $(seth call "$admin" "getProxyImplementation(address)(address)" "$proxy" --chain "$SOURCE_CHAIN" --from "$ETH_FROM") != "$newImp"; then
    (log "check migration failed."; exit 1;)
  fi
  log "migration finished."
}

deploy_v2() {
  NAME=$1
  ARGS=${@:2}

  # find file path
  CONTRACT_PATH=$(find ./$SRC_DIR -name $NAME.f.sol)
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
  GAS=$(seth estimate --from "$ETH_FROM" --create "$BYTECODE" "$FUNCSIG$ARGS" --chain "$SOURCE_CHAIN")

  # deploy
  ADDRESS=$(set -x; seth send --from "$ETH_FROM" --create "$BYTECODE" "$FUNCSIG$ARGS" -- --gas "$GAS" --chain "$SOURCE_CHAIN")

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

gen_lane_id() {
  python3 -c "print(
    hex(
      ($1 << 64) +
      ($2 << 96) +
      ($3 << 128) +
      ($4 << 160)
    )
  )"
}
