#!/bin/bash

set -ex

if [[ "$1" ]]
then
    RULE="--rule $1"
fi

certoraRun harness/SimpleFeeMarketHarness.sol:SimpleFeeMarketHarness \
    --verify SimpleFeeMarketHarness:specs/SimpleFeeMarket.spec \
    --solc solc-0.7.6 \
    $RULE \
    --msg "SimpleFeeMarket"

    # --rule_sanity basic \
    # --optimistic_loop \
    # --typecheck_only \
    # --multi_assert_check \
