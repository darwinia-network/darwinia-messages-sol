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

accounts=($(ethsign ls | awk '{print tolower($1)}' | sort))

for account in "${accounts[@]}"; do
  if test $account == "0xcc5e48beb33b83b8bd0d9d9a85a8f6a27c51f5c5" -o $account == "0x00a1537d251a6a4c4effab76948899061fea47b9"; then
    sig=$(ethsign msg --from $account --data "${commitment}" --no-prefix --passphrase-file "$pw2")
  else
    sig=$(ethsign msg --from $account --data "${commitment}" --no-prefix --passphrase-file "$pw1")
  fi
  p $account $sig
done

echo "----------------------------------------------------------------"
DOMAIN_SEPARATOR="0xfe0c2a6bde911dc91bbb4830c55642356a387000f9d41859b5a820081ecc44c8"
HEADER_PRIFIX="0x1901"
data=0x${HEADER_PRIFIX:2}${DOMAIN_SEPARATOR:2}${commitmentHash:2}
echo "data" $data
dataHash=$(seth keccak $data)
echo "dataHash" $dataHash

for account in "${accounts[@]}"; do
  if test $account != "0xcc5e48beb33b83b8bd0d9d9a85a8f6a27c51f5c5" -a $account != "0x00a1537d251a6a4c4effab76948899061fea47b9" -a $account != "0xb13f16a6772c5a0b37d353c07068ca7b46297c43"; then
    sig=$(ethsign msg --from $account --data "${data}" --no-prefix --passphrase-file "$pw1")
    p $account $sig
  fi
done
