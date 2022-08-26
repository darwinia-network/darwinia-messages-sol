#!/use/bin/env bash

set -e

. $(dirname $0)/color.sh

s=pangoro
t=goerli

root_dir=$(realpath .)

echo "############# ChainMessageCommitter ###############"
ADDRESSES_FILE="${root_dir}/bin/addr/${mode}/${s}.json"
cmt=$(cat $ADDRESSES_FILE | jq -r ".ChainMessageCommitterProxy")
origin_block_number=$(seth block-number --chain $s)
p2 "block_number" "$origin_block_number"
origin_message_root=$(seth call $cmt "commitment()" --chain $s)
p2 "message_root" "$origin_message_root"

ADDRESSES_FILE="${root_dir}/bin/addr/${mode}/${t}.json"
lc=$(cat $ADDRESSES_FILE | jq -r ".pangoro.DarwiniaLightClientProxy")

echo "############# DarwiniaLightClient ###############"
block_number=$(seth call $lc "block_number()(uint)" --chain $t)
# p2 "block_number" "$block_number"

message_root=$(seth call $lc "merkle_root()(bytes32)" --chain $t)
# p2 "message_root" "$message_root"

if [ "$message_root" != "$origin_message_root" ]; then
  echo "syncing"
  echo "\
${TPUT_YELLOW}block_number   $block_number
${TPUT_RED}message_root   $message_root${TPUT_RESET} -> ${TPUT_GREEN}$origin_message_root ${TPUT_RESET}"
else
  echo "synced"
  echo "\
${TPUT_GREEN}block_number   $block_number
${TPUT_GREEN}message_root   $message_root${TPUT_RESET}"
fi

