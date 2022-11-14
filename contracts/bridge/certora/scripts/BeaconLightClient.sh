#!/bin/bash

set -ex

if [[ "$1" ]]
then
    RULE="--rule $1"
fi

certoraRun certora/spec/BeaconLightClient.sol:BeaconLightClient \
    --verify BeaconLightClient:certora/spec/BeaconLightClient.spec \
    --solc solc-0.7.6 \
    --rule_sanity basic \
    $RULE \
    --msg "BeaconLightClient"

    # --typecheck_only
    # --optimistic_loop \
    # --multi_assert_check \
