#!/usr/bin/env bash

set -eo pipefail

export SOURCE_CHAIN=${from:?"!from"}
export TARGET_CHAIN=${to:?"!to"}
export DAO=${dao?}

. $(dirname $0)/base.sh
. $(dirname $0)/auth-checker.sh


# load_addresses
# load_addresses $ADDRESSES_FILE $TARGET_CHAIN

BridgeProxyAdmin=$(load_staddr "BridgeProxyAdmin")
ChainMessageCommitter=$(load_staddr "ChainMessageCommitter")
FeeMarket=$(load_saddr "FeeMarket")
FeeMarketProxy=$(load_saddr "FeeMarketProxy")
BeaconLightClient=$(load_saddr "BeaconLightClient")
EthereumSerialLaneVerifier=$(load_saddr "EthereumSerialLaneVerifier")
SerialOutboundLane=$(load_saddr "SerialOutboundLane")
SerialInboundLane=$(load_saddr "SerialInboundLane")
LaneMessageCommitter=$(load_saddr "LaneMessageCommitter")

# auth check
check_owner "BridgeProxyAdmin" "DAO"
check_admin "FeeMarketProxy" "BridgeProxyAdmin"
check_imp   "FeeMarketProxy" "FeeMarket"
check_setter "FeeMarketProxy" "DAO"
check_setter "EthereumSerialLaneVerifier" "DAO"
check_setter "ChainMessageCommitter" "DAO"
check_setter "LaneMessageCommitter" "DAO"

# config check
this_chain_pos=$(load_conf ".Chain.this_chain_pos")
this_out_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[0].this_lane_pos")
this_in_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[1].this_lane_pos")
bridged_chain_pos=$(load_conf ".Chain.Lanes[1].bridged_chain_pos")
bridged_in_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[0].bridged_lane_pos")
bridged_out_lane_pos=$(load_conf ".Chain.Lanes[1].lanes[1].bridged_lane_pos")
