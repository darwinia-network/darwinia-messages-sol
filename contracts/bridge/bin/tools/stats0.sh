#!/use/bin/env bash

set -e

. $(dirname $0)/color.sh

s=goerli
t=pangoro
beacon_endpoint="http://127.0.0.1:5052"

root_dir=$(realpath .)
ADDRESSES_FILE="${root_dir}/bin/addr/${mode}/${t}.json"

cl=$(cat $ADDRESSES_FILE | jq -r ".goerli.BeaconLightClient")
el=$(cat $ADDRESSES_FILE | jq -r ".goerli.EthereumExecutionLayerProxy")

echo "############# EthereumConsensusLayer ###############"
keys='slot proposer_index parent_root state_root body_root'
clheader=$(seth call $cl "finalized_header()(uint64,uint64,bytes32,bytes32,bytes32)" --chain $t)
p "$keys" "$clheader"

slot=$(echo $clheader | cut -d' ' -f "1")

echo "############# EthereumExecutionLayer ###############"
state_root=$(seth call $el "state_root()(bytes32)" --chain $t)
# p2 "state_root" "$state_root"
elheader=$(curl -fsSX GET $beacon_endpoint/eth/v2/beacon/blocks/$slot -H  "accept: application/json" | jq ".data.message.body.execution_payload")
block_number=$(echo "$elheader" | jq -r ".block_number")
merge_state_root=$(echo "$elheader" | jq -r ".state_root")

if [ "$state_root" != "$merge_state_root" ]; then
  echo "syncing"
  echo "\
${TPUT_YELLOW}block_number   $block_number
${TPUT_RED}state_root     $state_root${TPUT_RESET} -> ${TPUT_GREEN}$merge_state_root ${TPUT_RESET}"
else
  echo "synced"
  echo "\
${TPUT_GREEN}block_number   $block_number
${TPUT_GREEN}state_root     $state_root${TPUT_RESET}"
fi
