#!/usr/bin/env bash

set -e

export SETH_CHAIN=crab
export ETH_FROM=0x0085a7739de16716b5dd5a07d42d08708769c988

CLAIMS=0xA561c8F6AC9eCb31e0793fBe2CCEc136a7e4bE84

path="${PWD}/data/${SETH_CHAIN}/root/${1}_${2}.json"
echo "path: $path"

root=$(cat $path)
expiry=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
seth send -F $ETH_FROM $CLAIMS "addNewGiveaway(bytes32,uint)" $root $expiry --chain $SETH_CHAIN
