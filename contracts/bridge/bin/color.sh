#!/usr/bin/env bash

set -eo pipefail

p2() { printf "%-14s %-32s \n" "$1" "$2"; }
p() {
  local keys=("$1")
  local values="$2"
  local i=0
  for key in ${keys[@]}; do
    ((i="$i"+1))
    value=$(echo $values | cut -d' ' -f "$i")
    p2 "${key}" "$value"
  done
}

# green log helper
GREEN='\033[0;32m'
NC='\033[0m' # No Color
log() {
  printf '%b\n' "${GREEN}${*}${NC}" >&2
  echo ""
}

# Coloured output helpers
if command -v tput >/dev/null 2>&1; then
  if [ $(($(tput colors 2>/dev/null))) -ge 8 ]; then
    # Enable colors
    TPUT_RESET="$(tput sgr 0)"
    TPUT_YELLOW="$(tput setaf 3)"
    TPUT_RED="$(tput setaf 1)"
    TPUT_BLUE="$(tput setaf 4)"
    TPUT_GREEN="$(tput setaf 2)"
    TPUT_WHITE="$(tput setaf 7)"
    TPUT_BOLD="$(tput bold)"
  fi
fi
