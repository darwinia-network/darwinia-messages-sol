#!/usr/bin/env bash
set -e

path="./beefy-fixture-data.json"
pw1="./pw1"
pw2="./pw2"

id=$(seth --to-uint64 $(jq -r ".commitment.payload.nextValidatorSet.id" "$path"))  
len=$(seth --to-uint32 $(jq -r ".commitment.payload.nextValidatorSet.len" "$path"))  
root=$(jq -r ".commitment.payload.nextValidatorSet.root" "$path")  
network=$(jq -r ".commitment.payload.network" "$path")  
mmr=$(jq -r ".commitment.payload.mmr" "$path")  
blockNumber=$(seth --to-uint32 $(jq -r ".commitment.blockNumber" "$path"))  
validatorSetId=$(seth --to-uint64 $(jq -r ".commitment.validatorSetId" "$path"))  

commitment=0x${network:2}${mmr:2}${id:2}${len:2}${root:2}${blockNumber:2}${validatorSetId:2}
echo "commitment: $commitment"
commitmentHash=$(seth keccak "$commitment")
echo "commitmentHash: $commitmentHash"

sig1=$(ethsign msg --from 0xB13f16A6772C5A0b37d353C07068CA7B46297c43 --data "${commitment}" --no-prefix --passphrase-file "$pw1")
echo "sig1: $sig1"

sig2=$(ethsign msg --from 0xcC5E48BEb33b83b8bD0D9d9A85A8F6a27C51F5C5 --data "${commitment}" --no-prefix --passphrase-file "$pw2")
echo "sig2: $sig2"

sig3=$(ethsign msg --from 0x00a1537d251a6a4c4effAb76948899061FeA47b9 --data "${commitment}" --no-prefix --passphrase-file "$pw2")
echo "sig3: $sig3"

