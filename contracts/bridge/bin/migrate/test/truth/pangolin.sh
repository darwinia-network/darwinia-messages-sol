#!/usr/bin/env bash

set -e

unset SOURCE_CHAIN
unset TARGET_CHAIN
unset ETH_RPC_URL
export SOURCE_CHAIN=${from:?"!from"}
export TARGET_CHAIN=${to:?"!to"}

. $(dirname $0)/base.sh

# arbitrum airnoderrp
airnoderrp=$(load_conf ".Oracle.${TARGET_CHAIN}.arinoderrp")
airnode=$(load_conf ".Oracle.${TARGET_CHAIN}.arinode")
endpointId=$(load_conf ".Oracle.${TARGET_CHAIN}.endpointId")
sponsor=$(load_conf ".Oracle.${TARGET_CHAIN}.sponsor")
sponsorwallet=$(load_conf ".Oracle.${TARGET_CHAIN}.sponsorwallet")
AirnodeRrpRequester=$(deploy AirnodeRrpRequester \
  $airnoderrp \
  $airnode \
  $endpointId \
  $sponsor \
  $sponsorwallet)

ArbitrumRequestOracle=$(deploy ArbitrumRequestOracle $AirnodeRrpRequester)

ArbitrumSerialLaneVerifier=$(load_saddr "ArbitrumSerialLaneVerifier")
SETH_CHAIN=$SOURCE_CHAIN seth send -F $ETH_FROM $ArbitrumSerialLaneVerifier "changeLightClient(address)" $ArbitrumRequestOracle --chain $SOURCE_CHAIN
