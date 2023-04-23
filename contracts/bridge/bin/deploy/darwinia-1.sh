#!/usr/bin/env bash

set -e

unset SOURCE_CHAIN
unset TARGET_CHAIN
unset ETH_RPC_URL
export SOURCE_CHAIN=${from:?"!from"}
export TARGET_CHAIN=${to:?"!to"}

. $(dirname $0)/base.sh

BridgeProxyAdmin=$(load_staddr "BridgeProxyAdmin")
XMESSAGEGATEWAY=$(dapp address $deployer $nonce)
SerialOutboundLane=$(load_saddr "SerialOutboundLane")
SerialInboundLane=$(load_saddr "SerialInboundLane")
deployer=$(load_taddr "DEPLOYER")
nonce=$(seth nonce $deployer --chain $TARGET_CHAIN)

MessageGateway=$(deploy MessageGateway \
  $XMESSAGEGATEWAY \
  $SerialOutboundLane \
  $SerialInboundLane)

MessageGatewayProxy=$(deploy MessageGatewayProxy \
  $MessageGateway \
  $BridgeProxyAdmin 0x)
