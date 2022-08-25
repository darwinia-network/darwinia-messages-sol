#!/use/bin/env bash

set -e

toUpper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

toLower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

load_conf() {
  if [ -z "$1" ]
    then
      echo "conf: Invalid key"
      exit 1
  fi
  local key; key=$1
  jq -r "${key}" "$CONFIG_FILE"
}

load-addresses() {
  path=${ADDRESSES_FILE:-$1}
  if [[ ! -e "$path" ]]; then
    echo "Addresses file not found: $path not found"
    exit 1
  fi
  echo $path
  local exports
  [[ -z "${2}" ]] && {
    exports=$(cat $path | jq -r " . | \
      to_entries|map(\"\(.key)=\(.value|strings)\")|.[]")
    for e in $exports; do export "$e"; done
  } || {
    exports=$(cat $path | jq -r " .[\"$2\"] | \
      to_entries|map(\"\(.key)=\(.value|strings)\")|.[]")
    for e in $exports; do export "$2"_"$e"; done
  }
}
