#!/usr/bin/env bash

set -eo pipefail

export NONCE_TMP_FILE0
export NONCE_TMP_FILE1

clean() {
  test -f "$NONCE_TMP_FILE0" && rm "$NONCE_TMP_FILE0"
  test -f "$NONCE_TMP_FILE1" && rm "$NONCE_TMP_FILE1"
}

if [[ -z "$NONCE_TMP_FILE0" && -z "$NONCE_TMP_FILE1" && -n "$ETH_FROM" ]]; then
  nonce0=$(seth nonce "$ETH_FROM" --chain $Chain0)
  nonce1=$(seth nonce "$ETH_FROM" --chain $Chain1)
  NONCE_TMP_FILE0=$(mktemp -t $Chain0)
  NONCE_TMP_FILE1=$(mktemp -t $Chain1)
  echo "$nonce0" > "$NONCE_TMP_FILE0"
  echo "$nonce1" > "$NONCE_TMP_FILE1"
  trap clean EXIT
fi

nonce() {
  set -e
  local n;
  local file;

  CHAIN=${1?}
  if [[ "$CHAIN" == "$Chain0" ]]; then
    file=$NONCE_TMP_FILE0;
  elif [[ "$CHAIN" == "$Chain1" ]]; then
    file=$NONCE_TMP_FILE1;
  else
    echo "NONCE_TMP_FILE not fould, please check chain config."
    exit 1
  fi
  n=$(cat "$file")
  echo $n
}

inc() {
  set -e
  local n;
  local file;

  CHAIN=${1?}
  if [[ "$CHAIN" == "$Chain0" ]]; then
    file=$NONCE_TMP_FILE0;
  elif [[ "$CHAIN" == "$Chain1" ]]; then
    file=$NONCE_TMP_FILE1;
  else
    echo "NONCE_TMP_FILE not fould, please check chain config."
    exit 1
  fi
  n=$(cat "$file")
  echo $((n + 1)) > "$file"
}
