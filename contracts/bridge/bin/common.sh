#!/usr/bin/env bash

set -eo pipefail

if [[ ${DEBUG} ]]; then
	set -x
fi

. $(dirname $0)/base.sh

# Setup addresses file
cat >"$ADDRESSES_FILE" <<EOF
{
    "DEPLOYER": "$ETH_FROM"
}
EOF
