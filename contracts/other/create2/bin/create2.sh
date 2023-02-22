#!/usr/bin/env bash
# bash bin/create2.sh 2pNg9mbeYy63oYkuneup5rBEW1sW5TYC4WDSogjhR8nsgmQ2 0 [0x75B7B700710EedC26dF06B2E7555153912c69189,0xf24FF3a9CF04c71Dbc94D0b566f7A27B94566cac,0x529A1c9df530bcbaB9ab1a61fcd0cAbddC5ef094] 2

set -e

# export SETH_CHAIN=pangoro
export ETH_RPC_URL=http://g1.dev.darwinia.network:10000
export ETH_FROM=0x0f14341A7f464320319025540E8Fe48Ad0fe5aec

CREATE2=0xF09FE18d3f4b4345b47c098C8B8Fba7743418aA4

sub_mul_sig=$1
nonce=$2
owners=$3
threhold=$4

pub_key=$(subkey inspect $sub_mul_sig | grep 'hex' | awk '{print $4}')
salt=$(seth call $CREATE2 "computeSalt(bytes32,uint)" $pub_key $nonce)
echo "salt: $salt"

addr=$(seth call $CREATE2 "computeAddress(bytes32,address[],uint)(address)" $salt $owners $threhold)
echo "addr: $addr"

seth send $CREATE2 "deploy(bytes32,address[],uint)(address)" $salt $owners $threhold
