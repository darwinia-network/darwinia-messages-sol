#!/usr/bin/env bash
set -e

p() { printf "%-42s %-132s\n" "$1" "$2"; }

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

accounts=($(ethsign ls | awk '{print $1}'))

for account in "${accounts[@]}"; do
  if test $account == "0xcC5E48BEb33b83b8bD0D9d9A85A8F6a27C51F5C5" -o $account == "0x00a1537d251a6a4c4effAb76948899061FeA47b9"; then
    sig=$(ethsign msg --from $account --data "${commitment}" --no-prefix --passphrase-file "$pw2")
  else
    sig=$(ethsign msg --from $account --data "${commitment}" --no-prefix --passphrase-file "$pw1")
  fi
  p $account $sig
done

network=$(jq -r ".guardMessage.network" "$path")  
methodID=$(jq -r ".guardMessage.methodID" "$path")  
nextGuardSetId=$(seth --to-uint32 $(jq -r ".guardMessage.nextGuardSetId" "$path"))
nextGuardSetLen=$(seth --to-uint32 $(jq -r ".guardMessage.nextGuardSetLen" "$path"))
nextGuardSetRoot=$(jq -r ".guardMessage.nextGuardSetRoot" "$path")  
nextGuardSetThreshold=$(seth --to-uint32 $(jq -r ".guardMessage.nextGuardSetThreshold" "$path"))

message=0x${network:2}${methodID:2}${nextGuardSetId:2}${nextGuardSetLen:2}${nextGuardSetRoot:2}${nextGuardSetThreshold:2}

echo "----------------------------------------------------------------"
echo "message" $message
messageHash=$(seth keccak $message)
echo "messageHash" $messageHash

for account in "${accounts[@]}"; do
  if test $account != "0xcC5E48BEb33b83b8bD0D9d9A85A8F6a27C51F5C5" -a $account != "0x00a1537d251a6a4c4effAb76948899061FeA47b9" -a $account != "0xB13f16A6772C5A0b37d353C07068CA7B46297c43"; then
    sig=$(ethsign msg --from $account --data "${message}" --no-prefix --passphrase-file "$pw1")
    p $account $sig
  fi
done
