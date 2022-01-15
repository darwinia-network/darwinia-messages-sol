#!/usr/bin/env bash
set -e

p() { printf "%-2s %-42s %-132s\n" "$1" "$2" "$3"; }

pw1="./pw1"

accounts=($(ethsign ls | awk '{print tolower($1)}' | sort))

g_nonce=0

encode_struct_hash() {
  GUARD_TYPEHASH="0x20823b509c0ff3e2ea0853237833f25b5c32c94d52327fd569cf245995a8206b"
  NETWORK="0x4372616200000000000000000000000000000000000000000000000000000000"  
  local methodID=$(seth sig ${1?})
  local params=${2?} 
  local nonce=$(seth --to-uint256 $g_nonce)
  structData=$(ethabi encode params -v bytes32 ${GUARD_TYPEHASH:2} -v bytes32 ${NETWORK:2} -v bytes4 ${methodID:2} -v bytes ${params} -v uint256 ${nonce:2}) 
  structHash=$(seth keccak "0x$structData")
  echo $structHash
}

encode_data_hash() {
  DOMAIN_SEPARATOR="0xebb42714baeadc1e3697298c70e43a8edb9fa46ea3e5622f87e4c41b9f3c7ffe"
  HEADER_PRIFIX="0x1901"
  data=0x${HEADER_PRIFIX:2}${DOMAIN_SEPARATOR:2}${1:2}
  dataHash=$(seth keccak $data)
  echo $data
}

sigs=(
  "addGuardWithThreshold(address,uint256,bytes[])" 
  "removeGuard(address,address,uint256,bytes[])"
  "swapGuard(address,address,address,bytes[])"
  "changeThreshold(uint256,bytes[])"
)

params=(
  $(ethabi encode params -v '(address,uint256)' '(B13f16A6772C5A0b37d353C07068CA7B46297c43,0000000000000000000000000000000000000000000000000000000000000003)')
  $(ethabi encode params -v '(address,address,uint256)' '(0000000000000000000000000000000000000001,B13f16A6772C5A0b37d353C07068CA7B46297c43,0000000000000000000000000000000000000000000000000000000000000002)')
  $(ethabi encode params -v '(address,address,address)' '(0000000000000000000000000000000000000001,E78399B095Df195f10b56724DD22AA88fC295B4a,B13f16A6772C5A0b37d353C07068CA7B46297c43)')
  $(ethabi encode params -v '(uint256)' '(0000000000000000000000000000000000000000000000000000000000000003)')
)

for (( i=0; i<${#sigs[@]}; i++ )); do
  sig="${sigs[$i]}"
  param="${params[$i]}"
  structHash=$(encode_struct_hash $sig $param)
  data=$(encode_data_hash $structHash)
  g_nonce=$((g_nonce + 1))
  for account in "${accounts[@]}"; do
    if test $account != "0xcc5e48beb33b83b8bd0d9d9a85a8f6a27c51f5c5" -a $account != "0x00a1537d251a6a4c4effab76948899061fea47b9" -a $account != "0xb13f16a6772c5a0b37d353c07068ca7b46297c43"; then
      sig=$(ethsign msg --from $account --data "${data}" --no-prefix --passphrase-file "$pw1")
      p "$i" $account $sig
    fi
  done
done
