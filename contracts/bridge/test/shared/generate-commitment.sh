#!/usr/bin/env bash
set -ex

path="${PWD}/beefy-fixture-data.json"

id=$(jq -r ".commitment.payload.nextValidatorSet.id" "$path")  
len=$(jq -r ".commitment.payload.nextValidatorSet.len" "$path")  
root=$(jq -r ".commitment.payload.nextValidatorSet.root" "$path")  
mmr=$(jq -r ".commitment.payload.mmr" "$path")  
blockNumber=$(jq -r ".commitment.blockNumber" "$path")  
validatorSetId=$(jq -r ".commitment.validatorSetId" "$path")  

