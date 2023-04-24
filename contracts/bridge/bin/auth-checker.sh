#!/usr/bin/env bash

set -eo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ok() {
  printf '%b\n' "${GREEN}✓ OK${NC}"
}

notok() {
  printf '%b\n' "${RED}❌NOT OK${NC}"
}

check() {
  printf "CFG: %s -> %s -> " "${1}" "${2}"
  if [[ $(toLower "${!2}") == $(toLower "${!2}") ]]; then
    ok
  else
    notok
  fi
}

ADMIN_SLOT="0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
check_admin() {
  local CHECK
  CHECK=$(seth storage "${!1}" "$ADMIN_SLOT" --chain $SOURCE_CHAIN)
  CHECK=$(seth --abi-decode "f()(address)" "$CHECK")

  printf "ADM: %s -> %s -> " "${1}" "${2}"
  if [[ $(toLower "${!2}") == $(toLower "${CHECK}") ]]; then
    ok
  else
    notok
  fi
}

IMPLEMENTATION_SLOT="0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
check_imp() {
  local CHECK
  CHECK=$(seth storage "${!1}" "$IMPLEMENTATION_SLOT" --chain $SOURCE_CHAIN)
  CHECK=$(seth --abi-decode "f()(address)" "$CHECK")

  printf "IMP: %s -> %s -> " "${1}" "${2}"
  if [[ $(toLower "${!2}") == $(toLower "${CHECK}") ]]; then
    ok
  else
    notok
  fi
}

check_owner() {
  local CHECK
  CHECK=$(seth call "${!1}" 'owner()(address)' --chain $SOURCE_CHAIN)

  printf "OWN: %s -> %s -> " "${1}" "${2}"
  if [[ $(toLower "${!2}") == $(toLower "${CHECK}") ]]; then
    ok
  else
    notok
  fi
}

check_setter() {
  local CHECK
  CHECK=$(seth call "${!1}" 'setter()(address)' --chain $SOURCE_CHAIN)

  printf "SET: %s -> %s -> " "${1}" "${2}"
  if [[ $(toLower "${!2}") == $(toLower "${CHECK}") ]]; then
    ok
  else
    notok
  fi
}
