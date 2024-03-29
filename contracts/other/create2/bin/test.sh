#!/usr/bin/env bash

set -e

export SETH_CHAIN=pangoro
export ETH_FROM=0x0f14341A7f464320319025540E8Fe48Ad0fe5aec

WALLET=0x76D3546D8a085743e5eC5b3Dd2d8D3dD2C38103F

seth call $WALLET "getOwners()(address[])"
seth call $WALLET "required()(uint)"

data=$(seth calldata "changeRequirement(uint)" 1)
value=0
count=$(seth call -F $ETH_FROM $WALLET "submitTransaction(address,uint,bytes)(uint)" $WALLET $value $data)
seth send -F $ETH_FROM $WALLET "submitTransaction(address,uint,bytes)(uint)" $WALLET $value $data
seth send -F 0xcC5E48BEb33b83b8bD0D9d9A85A8F6a27C51F5C5 $WALLET "confirmTransaction(uint)" $count
