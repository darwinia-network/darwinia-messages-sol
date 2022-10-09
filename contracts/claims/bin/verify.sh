#!/usr/bin/env bash

set -e

# export SETH_CHAIN=crab
# export ETH_FROM=0x0085a7739de16716b5dd5a07d42d08708769c988
# CLAIMS=0xA561c8F6AC9eCb31e0793fBe2CCEc136a7e4bE84

export SETH_CHAIN=ethlive
export ETH_FROM=0x7aE77149ed38c5dD313e9069d790Ce7085caf0A6
CLAIMS=0x15fC591601044351868b13a5B629c170Bf3F30A0

path="${PWD}/data/${SETH_CHAIN}/verify/${1}_${2}.json"
echo "path: $path"

tos=$(jq -r ". | keys_unsorted[]" "$path")
for to in $tos;do
  calldata=$(jq -r '.["'${to}'"] | values' "$path")
  echo "verify [$to] claim proof"
  seth call -F $ETH_FROM $CLAIMS $calldata --chain $SETH_CHAIN
done
