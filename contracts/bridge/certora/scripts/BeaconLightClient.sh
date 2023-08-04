#!/bin/bash

set -ex

if [[ "$1" ]]
then
    RULE="--rule $1"
fi

certoraRun harness/BeaconLightClientHarness.sol:BeaconLightClientHarness \
    --verify BeaconLightClientHarness:specs/BeaconLightClient.spec \
    --solc solc-0.7.6 \
    --rule_sanity basic \
    $RULE \
    --optimistic_loop \
    --include_empty_fallback \
    --msg "BeaconLightClient"

    # --debug \
    # --typecheck_only \
    # --multi_assert_check \
