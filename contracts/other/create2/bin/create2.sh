#!/usr/bin/env bash
# bash bin/create2.sh 2qFg1JQuhvNo8iUoNMosN1jVf9jKgGTCSBVm5DxmHDMwkuxY [0x75B7B700710EedC26dF06B2E7555153912c69189,0xf24FF3a9CF04c71Dbc94D0b566f7A27B94566cac,0x529A1c9df530bcbaB9ab1a61fcd0cAbddC5ef094] 2

set -e

export SETH_CHAIN=pangoro
export ETH_FROM=0x0f14341A7f464320319025540E8Fe48Ad0fe5aec

CREATE2=0x6c25E0c1f57d7E78d7eB8D350f11204137EF71bE

sub_mul_sig=$1
owners=$2
threhold=$3

pub_key=$(subkey inspect $sub_mul_sig | grep 'hex' | awk '{print $4}')
addr=$(seth call $CREATE2 "computeAddress(bytes32,address[],uint)(address)" $pub_key $owners $threhold)
echo "addr: $addr"

seth call $CREATE2 "deploy(bytes32,address[],uint)(address)" $pub_key $owners $threhold
