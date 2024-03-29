#!/usr/bin/env bash

set -e

unset SOURCE_CHAIN
unset TARGET_CHAIN
unset ETH_RPC_URL
export SOURCE_CHAIN=darwinia
export TARGET_CHAIN=ethereum

SOURCE_DAO=0xB29DA7C1b1514AB342afbE6AB915252Ad3f87E4d
TARGET_DAO=0xFfD0a972E371B8cFE34b8C9176CE77C0fF8D43e1

. $(dirname $0)/base.sh

ChainMessageCommitter=$(load_staddr "ChainMessageCommitter")
LaneMessageCommitter=$(load_saddr "LaneMessageCommitter")
EthereumSerialLaneVerifier=$(load_saddr "EthereumSerialLaneVerifier")
SOURCE_FeeMarketProxy=$(load_saddr "FeeMarketProxy")
TARGET_FeeMarketProxy=$(load_taddr "FeeMarketProxy")

SETH_CHAIN=$SOURCE_CHAIN send -F $ETH_FROM $ChainMessageCommitter      "changeSetter(address)" $SOURCE_DAO --chain $SOURCE_CHAIN
SETH_CHAIN=$SOURCE_CHAIN send -F $ETH_FROM $LaneMessageCommitter       "changeSetter(address)" $SOURCE_DAO --chain $SOURCE_CHAIN
SETH_CHAIN=$SOURCE_CHAIN send -F $ETH_FROM $EthereumSerialLaneVerifier "changeSetter(address)" $SOURCE_DAO --chain $SOURCE_CHAIN
SETH_CHAIN=$SOURCE_CHAIN send -F $ETH_FROM $SOURCE_FeeMarketProxy      "setSetter(address)"    $SOURCE_DAO --chain $SOURCE_CHAIN

SETH_CHAIN=$TARGET_CHAIN send -F $ETH_FROM $TARGET_FeeMarketProxy      "setSetter(address)"    $TARGET_DAO --chain $TARGET_CHAIN
