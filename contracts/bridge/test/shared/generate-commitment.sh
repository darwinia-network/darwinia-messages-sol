#!/usr/bin/env bash
set -e

path="./beefy-fixture-data.json"
pw1="./pw1"
pw2="./pw2"

id=$(seth --to-uint64 $(jq -r ".commitment.payload.nextValidatorSet.id" "$path"))  
len=$(seth --to-uint32 $(jq -r ".commitment.payload.nextValidatorSet.len" "$path"))  
root=$(jq -r ".commitment.payload.nextValidatorSet.root" "$path")  
mmr=$(jq -r ".commitment.payload.mmr" "$path")  
blockNumber=$(seth --to-uint32 $(jq -r ".commitment.blockNumber" "$path"))  
validatorSetId=$(seth --to-uint64 $(jq -r ".commitment.validatorSetId" "$path"))  

commitment=0x${mmr:2}${id:2}${len:2}${root:2}${blockNumber:2}${validatorSetId:2}
# 0xfab049d511b54f8d1169f85fe8add36c54a76c36d20737a80b1f0e72179b7d5f00000000000000010000000392622f8520ac4c57e72783387099b2bc696523782c5e5fae137faff102268e070000000c0000000000000000
echo "commitment: $commitment"
# 0x927d1947c20d4b90965610ae35ace4e3fc6fb4a024f8391a1b95de42096a7a4d
commitmentHash=$(seth keccak "$commitment")
echo "commitmentHash: $commitmentHash"

sig1=$(ethsign msg --from 0xB13f16A6772C5A0b37d353C07068CA7B46297c43 --data "${commitment}" --no-prefix --passphrase-file "$pw1")
echo "sig1: $sig1"

sig2=$(ethsign msg --from 0xcC5E48BEb33b83b8bD0D9d9A85A8F6a27C51F5C5 --data "${commitment}" --no-prefix --passphrase-file "$pw2")
echo "sig2: $sig2"

sig3=$(ethsign msg --from 0x00a1537d251a6a4c4effAb76948899061FeA47b9 --data "${commitment}" --no-prefix --passphrase-file "$pw2")
echo "sig3: $sig3"

