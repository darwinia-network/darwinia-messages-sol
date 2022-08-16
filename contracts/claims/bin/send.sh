#!/usr/bin/env bash

set -e

export SETH_CHAIN=crab
export SETH_ASYNC=yes
export ETH_FROM=0x0085a7739de16716b5dd5a07d42d08708769c988

path="${PWD}/data/${SETH_CHAIN}/data/${1}_${2}.json"
echo "path: $path"

to=0xA561c8F6AC9eCb31e0793fBe2CCEc136a7e4bE84
token=0xB29DA7C1b1514AB342afbE6AB915252Ad3f87E4d
ids=$(jq -r ".[].erc721[].ids[]" "$path")

echo $ids

# nonce=$(seth nonce $ETH_FROM)
# echo "nonce: ${nonce}"
# for id in $ids;do
#   echo "sending token [$id] to [$to]"
#   seth send -F "$ETH_FROM" -N "$nonce" $token "transferFrom(address,address,uint)" "${ETH_FROM?}" "${to?}" "${id?}" --chain "${SETH_CHAIN?}"
#   nonce=$(( ${nonce} + 1 ))
#   echo "sent token [$id] to [$to]"
# done
# echo "nonce: ${nonce}"
