#!/usr/bin/env bash

set -e

unset SOURCE_CHAIN
unset TARGET_CHAIN
unset ETH_RPC_URL
export SOURCE_CHAIN=${from:?"!from"}
export TARGET_CHAIN=${to:?"!to"}

. $(dirname $0)/base.sh

oracle=$(load_conf ".Oracle.${TARGET_CHAIN}")
ArbitrumFeedOracle=$(deploy ArbitrumFeedOracle $oracle)

ArbitrumSerialLaneVerifier=$(load_saddr "ArbitrumSerialLaneVerifier")
SETH_CHAIN=$SOURCE_CHAIN send -F $ETH_FROM $ArbitrumSerialLaneVerifier "changeLightClient(address)" $ArbitrumFeedOracle --chain $SOURCE_CHAIN
