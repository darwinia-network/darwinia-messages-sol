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
# check_admin   "FeeMarketProxy"              "BridgeProxyAdmin"
# check_imp     "FeeMarketProxy"              "FeeMarket"
# check_owner   "BridgeProxyAdmin"            "DAO"
# check_setter  "EthereumSerialLaneVerifier"  "DAO"
# check_setter  "ChainMessageCommitter"       "DAO"
# check_setter  "LaneMessageCommitter"        "DAO"
# check_setter  "FeeMarketProxy"              "DAO"

# config check
# fee market config
FEEMARKET_VAULT=$(load_conf ".FeeMarket.vault")
FEEMARKET_COLLATERAL_PERORDER=$(load_conf ".FeeMarket.collateral_perorder")
FEEMARKET_ASSIGNED_RELAYERS_NUMBER=$(load_conf ".FeeMarket.assigned_relayers_number")
FEEMARKET_SLASH_TIME=$(load_conf ".FeeMarket.slash_time")
FEEMARKET_RELAY_TIME=$(load_conf ".FeeMarket.relay_time")
# 0.01 : 2000
FEEMARKET_PRICE_RATIO=$(load_conf ".FeeMarket.price_ratio")
FEEMARKET_DUTY_RATIO=$(load_conf ".FeeMarket.duty_ratio")

VAULT=$(seth call "$FeeMarketProxy" 'VAULT()(address)' --chain $SOURCE_CHAIN)
SLASH_TIME=$(seth call "$FeeMarketProxy" 'SLASH_TIME()(uint)' --chain $SOURCE_CHAIN)
RELAY_TIME=$(seth call "$FeeMarketProxy" 'RELAY_TIME()(uint)' --chain $SOURCE_CHAIN)
ASSIGNED_RELAYERS_NUMBER=$(seth call "$FeeMarketProxy" 'ASSIGNED_RELAYERS_NUMBER()(uint)' --chain $SOURCE_CHAIN)
PRICE_RATIO_NUMERATOR=$(seth call "$FeeMarketProxy" 'PRICE_RATIO_NUMERATOR()(uint)' --chain $SOURCE_CHAIN)
COLLATERAL_PER_ORDER=$(seth call "$FeeMarketProxy" 'COLLATERAL_PER_ORDER()(uint)' --chain $SOURCE_CHAIN)
DUTY_REWARD_RATIO=$(seth call "$FeeMarketProxy" 'DUTY_REWARD_RATIO()(uint)' --chain $SOURCE_CHAIN)
# check  "FEEMARKET_VAULT"                     "VAULT"
# check  "FEEMARKET_SLASH_TIME"                "SLASH_TIME"
# check  "FEEMARKET_RELAY_TIME"                "RELAY_TIME"
# check  "FEEMARKET_ASSIGNED_RELAYERS_NUMBER"  "ASSIGNED_RELAYERS_NUMBER"
# check  "FEEMARKET_PRICE_RATIO_NUMERATOR"     "PRICE_RATIO_NUMERATOR"
# check  "FEEMARKET_COLLATERAL_PER_ORDER"      "COLLATERAL_PER_ORDER"
# check  "DUTY_REWARD_RATIO"                   "DUTY_REWARD_RATIO"

# darwinia to eth2.0 bridge config
THIS_CHAIN_POS=$(load_conf ".Chain.this_chain_pos")
THIS_OUT_LANE_POS=$(load_conf ".Chain.Lanes[1].lanes[0].this_lane_pos")
THIS_IN_LANE_POS=$(load_conf ".Chain.Lanes[1].lanes[1].this_lane_pos")
BRIDGED_CHAIN_POS=$(load_conf ".Chain.Lanes[1].bridged_chain_pos")
BRIDGED_IN_LANE_POS=$(load_conf ".Chain.Lanes[1].lanes[0].bridged_lane_pos")
BRIDGED_OUT_LANE_POS=$(load_conf ".Chain.Lanes[1].lanes[1].bridged_lane_pos")
MAX_GAS_PER_MESSAGE=$(load_conf ".Chain.Lanes[1].lanes[1].max_gas_per_message")
OUTLANE_ID=$(gen_lane_id "$BRIDGED_IN_LANE_POS" "$BRIDGED_CHAIN_POS" "$THIS_OUT_LANE_POS" "$THIS_CHAIN_POS")
INLANE_ID=$(gen_lane_id "$BRIDGED_OUT_LANE_POS" "$BRIDGED_CHAIN_POS" "$THIS_IN_LANE_POS" "$THIS_CHAIN_POS")
OUTLANE_ID=$(seth --to-uint256 $OUTLANE_ID)
INLANE_ID=$(seth --to-uint256 $INLANE_ID)

CHAINMESSAGECOMMITTER_THIS_CHAIN_POSITION=$(seth call "$ChainMessageCommitter" 'THIS_CHAIN_POSITION()(uint)' --chain $SOURCE_CHAIN)
CHAINMESSAGECOMMITTER_MAXCHAINPOSITION=$(seth call "$ChainMessageCommitter" 'maxChainPosition()(uint)' --chain $SOURCE_CHAIN)
CHAINMESSAGECOMMITTER_LEAVE_1=$(seth call "$ChainMessageCommitter" 'leaveOf(uint)(address)' "$BRIDGED_CHAIN_POS" --chain $SOURCE_CHAIN)
check "CHAINMESSAGECOMMITTER_THIS_CHAIN_POSITION" "THIS_CHAIN_POS"
check "CHAINMESSAGECOMMITTER_MAXCHAINPOSITION" "BRIDGED_CHAIN_POS"
check "CHAINMESSAGECOMMITTER_LEAVE_1" "LaneMessageCommitter"

LANEMESSAGECOMMITTER_THIS_CHAIN_POSITION=$(seth call "$LaneMessageCommitter" 'THIS_CHAIN_POSITION()(uint)' --chain $SOURCE_CHAIN)
LANEMESSAGECOMMITTER_BRIDGED_CHAIN_POSITION=$(seth call "$LaneMessageCommitter" 'BRIDGED_CHAIN_POSITION()(uint)' --chain $SOURCE_CHAIN)
LANEMESSAGECOMMITTER_LEAVE_0=$(seth call "$LaneMessageCommitter" 'leaveOf(uint)(address)' 0 --chain $SOURCE_CHAIN)
LANEMESSAGECOMMITTER_LEAVE_1=$(seth call "$LaneMessageCommitter" 'leaveOf(uint)(address)' 1 --chain $SOURCE_CHAIN)
check "LANEMESSAGECOMMITTER_THIS_CHAIN_POSITION" "THIS_CHAIN_POS"
check "LANEMESSAGECOMMITTER_BRIDGED_CHAIN_POSITION" "BRIDGED_CHAIN_POS"
check "LANEMESSAGECOMMITTER_LEAVE_0" "SerialOutboundLane"
check "LANEMESSAGECOMMITTER_LEAVE_1" "SerialInboundLane"

SERIALOUTBOUNDLANE_LANE_INFO=$(seth call "$SerialOutboundLane" 'getLaneInfo()(uint32,uint32,uint32,uint32)' --chain $SOURCE_CHAIN)
SERIALOUTBOUNDLANE_LANE_ID=$(seth call "$SerialOutboundLane" 'getLaneId()' --chain $SOURCE_CHAIN)
SERIALOUTBOUNDLANE_THIS_CHAIN_POS=$(echo $SERIALOUTBOUNDLANE_LANE_INFO | cut -d' ' -f 1)
SERIALOUTBOUNDLANE_THIS_LANE_POS=$(echo $SERIALOUTBOUNDLANE_LANE_INFO | cut -d' ' -f 2)
SERIALOUTBOUNDLANE_BRIDGED_CHAIN_POS=$(echo $SERIALOUTBOUNDLANE_LANE_INFO | cut -d' ' -f 3)
SERIALOUTBOUNDLANE_BRIDGED_LANE_POS=$(echo $SERIALOUTBOUNDLANE_LANE_INFO | cut -d' ' -f 4)
check "SERIALOUTBOUNDLANE_LANE_ID" "OUTLANE_ID"
check "SERIALOUTBOUNDLANE_THIS_LANE_POS" "THIS_CHAIN_POS"
check "SERIALOUTBOUNDLANE_THIS_LANE_POS" "THIS_OUT_LANE_POS"
check "SERIALOUTBOUNDLANE_BRIDGED_CHAIN_POS" "BRIDGED_CHAIN_POS"
check "SERIALOUTBOUNDLANE_BRIDGED_LANE_POS" "BRIDGED_IN_LANE_POS"

SERIALINBOUNDLANE_LANE_INFO=$(seth call "$SerialInboundLane" 'getLaneInfo()(uint32,uint32,uint32,uint32)' --chain $SOURCE_CHAIN)
SERIALINBOUNDLANE_LANE_ID=$(seth call "$SerialInboundLane" 'getLaneId()' --chain $SOURCE_CHAIN)
SERIALINBOUNDLANE_MAX_GAS_PER_MESSAGE=$(seth call "$SerialInboundLane" 'MAX_GAS_PER_MESSAGE()(uint)' --chain $SOURCE_CHAIN)
SERIALINBOUNDLANE_THIS_CHAIN_POS=$(echo $SERIALINBOUNDLANE_LANE_INFO | cut -d' ' -f 1)
SERIALINBOUNDLANE_THIS_LANE_POS=$(echo $SERIALINBOUNDLANE_LANE_INFO | cut -d' ' -f 2)
SERIALINBOUNDLANE_BRIDGED_CHAIN_POS=$(echo $SERIALINBOUNDLANE_LANE_INFO | cut -d' ' -f 3)
SERIALINBOUNDLANE_BRIDGED_LANE_POS=$(echo $SERIALINBOUNDLANE_LANE_INFO | cut -d' ' -f 4)
check "SERIALINBOUNDLANE_LANE_ID" "INLANE_ID"
check "SERIALINBOUNDLANE_THIS_LANE_POS" "THIS_CHAIN_POS"
check "SERIALINBOUNDLANE_THIS_LANE_POS" "THIS_IN_LANE_POS"
check "SERIALINBOUNDLANE_BRIDGED_CHAIN_POS" "BRIDGED_CHAIN_POS"
check "SERIALINBOUNDLANE_BRIDGED_LANE_POS" "BRIDGED_OUT_LANE_POS"
check "SERIALINBOUNDLANE_MAX_GAS_PER_MESSAGE" "MAX_GAS_PER_MESSAGE"
