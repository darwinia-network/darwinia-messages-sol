#!/usr/bin/env bash

set -e

unset SOURCE_CHAIN
unset TARGET_CHAIN
unset ETH_RPC_URL
export SOURCE_CHAIN=darwinia

SOURCE_ETH_FROM=0x7aE77149ed38c5dD313e9069d790Ce7085caf0A6
TARGET_ETH_FROM=0xa4FA5429544B225985F8438F2E013A9CCE7102f2
SOURCE_DAO=0xBd1a110ec476b4775c43905000288881367B1a88
TARGET_DAO=0x4710573B853fDD3561cb4F60EC9394f0155d5105

. $(dirname $0)/base.sh

ChainMessageCommitter=$(load_staddr "ChainMessageCommitter")
export TARGET_CHAIN=ethereum

LaneMessageCommitter=$(load_saddr "LaneMessageCommitter")
EthereumSerialLaneVerifier=$(load_saddr "EthereumSerialLaneVerifier")
SOURCE_FeeMarketProxy=$(load_saddr "FeeMarketProxy")
TARGET_FeeMarketProxy=$(load_taddr "FeeMarketProxy")

send -F $SOURCE_ETH_FROM $ChainMessageCommitter      "changeSetter(address)" $SOURCE_DAO --chain $SOURCE_CHAIN
send -F $SOURCE_ETH_FROM $LaneMessageCommitter       "changeSetter(address)" $SOURCE_DAO --chain $SOURCE_CHAIN
send -F $SOURCE_ETH_FROM $EthereumSerialLaneVerifier "changeSetter(address)" $SOURCE_DAO --chain $SOURCE_CHAIN
send -F $SOURCE_ETH_FROM $SOURCE_FeeMarketProxy      "setSetter(address)"    $SOURCE_DAO --chain $SOURCE_CHAIN

send -F $TARGET_ETH_FROM $TARGET_FeeMarketProxy      "setSetter(address)"    $TARGET_DAO --chain $TARGET_CHAIN
