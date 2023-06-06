#!/usr/bin/env bash

set -eo pipefail

export SOURCE_CHAIN=${from:?"!from"}
export TARGET_CHAIN=${to:?"!to"}
export DAO=${dao?}

. $(dirname $0)/base.sh
. $(dirname $0)/auth-checker.sh


# load_addresses
# load_addresses $ADDRESSES_FILE $TARGET_CHAIN
#
echo "=== Darwinia Checker ==="

BridgeProxyAdmin=$(load_staddr "BridgeProxyAdmin")
ChainMessageCommitter=$(load_staddr "ChainMessageCommitter")
FeeMarket=$(load_saddr "FeeMarket")
FeeMarketProxy=$(load_saddr "FeeMarketProxy")
BeaconLightClient=$(load_saddr "BeaconLightClient")
ArbitrumSerialLaneVerifier=$(load_saddr "ArbitrumSerialLaneVerifier")
SerialOutboundLane=$(load_saddr "SerialOutboundLane")
SerialInboundLane=$(load_saddr "SerialInboundLane")
LaneMessageCommitter=$(load_saddr "LaneMessageCommitter")

# auth check
check_admin   "FeeMarketProxy"              "BridgeProxyAdmin"
check_imp     "FeeMarketProxy"              "FeeMarket"
check_owner   "BridgeProxyAdmin"            "DAO"
check_setter  "ArbitrumSerialLaneVerifier"  "DAO"
check_setter  "ChainMessageCommitter"       "DAO"
check_setter  "LaneMessageCommitter"        "DAO"
check_setter  "FeeMarketProxy"              "DAO"

# config check
# fee market config
VAULT=$(load_conf ".FeeMarket.vault")
COLLATERAL_PER_ORDER=$(load_conf ".FeeMarket.${TARGET_CHAIN}.collateral_perorder")
ASSIGNED_RELAYERS_NUMBER=$(load_conf ".FeeMarket.${TARGET_CHAIN}.assigned_relayers_number")
SLASH_TIME=$(load_conf ".FeeMarket.${TARGET_CHAIN}.slash_time")
RELAY_TIME=$(load_conf ".FeeMarket.${TARGET_CHAIN}.relay_time")
PRICE_RATIO_NUMERATOR=$(load_conf ".FeeMarket.${TARGET_CHAIN}.price_ratio")
DUTY_REWARD_RATIO=$(load_conf ".FeeMarket.${TARGET_CHAIN}.duty_ratio")
FEEMARKET_VAULT=$(seth call "$FeeMarketProxy" 'VAULT()(address)' --chain $SOURCE_CHAIN)
FEEMARKET_SLASH_TIME=$(seth call "$FeeMarketProxy" 'SLASH_TIME()(uint)' --chain $SOURCE_CHAIN)
FEEMARKET_RELAY_TIME=$(seth call "$FeeMarketProxy" 'RELAY_TIME()(uint)' --chain $SOURCE_CHAIN)
FEEMARKET_ASSIGNED_RELAYERS_NUMBER=$(seth call "$FeeMarketProxy" 'ASSIGNED_RELAYERS_NUMBER()(uint)' --chain $SOURCE_CHAIN)
FEEMARKET_PRICE_RATIO_NUMERATOR=$(seth call "$FeeMarketProxy" 'PRICE_RATIO_NUMERATOR()(uint)' --chain $SOURCE_CHAIN)
FEEMARKET_COLLATERAL_PER_ORDER=$(seth call "$FeeMarketProxy" 'COLLATERAL_PER_ORDER()(uint)' --chain $SOURCE_CHAIN)
FEEMARKET_DUTY_REWARD_RATIO=$(seth call "$FeeMarketProxy" 'DUTY_REWARD_RATIO()(uint)' --chain $SOURCE_CHAIN)
check  "FEEMARKET_VAULT"                     "VAULT"
check  "FEEMARKET_SLASH_TIME"                "SLASH_TIME"
check  "FEEMARKET_RELAY_TIME"                "RELAY_TIME"
check  "FEEMARKET_ASSIGNED_RELAYERS_NUMBER"  "ASSIGNED_RELAYERS_NUMBER"
check  "FEEMARKET_PRICE_RATIO_NUMERATOR"     "PRICE_RATIO_NUMERATOR"
check  "FEEMARKET_COLLATERAL_PER_ORDER"      "COLLATERAL_PER_ORDER"
check  "FEEMARKET_DUTY_REWARD_RATIO"         "DUTY_REWARD_RATIO"

THIS_CHAIN_POS=$(load_conf ".Chain.this_chain_pos")
THIS_OUT_LANE_POS=$(load_conf ".Chain.Lanes[2].lanes[0].this_lane_pos")
THIS_IN_LANE_POS=$(load_conf ".Chain.Lanes[2].lanes[1].this_lane_pos")
BRIDGED_CHAIN_POS=$(load_conf ".Chain.Lanes[2].bridged_chain_pos")
BRIDGED_IN_LANE_POS=$(load_conf ".Chain.Lanes[2].lanes[0].bridged_lane_pos")
BRIDGED_OUT_LANE_POS=$(load_conf ".Chain.Lanes[2].lanes[1].bridged_lane_pos")
MAX_GAS_PER_MESSAGE=$(load_conf ".Chain.Lanes[2].lanes[1].max_gas_per_message")
OUTLANE_ID=$(gen_lane_id "$BRIDGED_IN_LANE_POS" "$BRIDGED_CHAIN_POS" "$THIS_OUT_LANE_POS" "$THIS_CHAIN_POS")
INLANE_ID=$(gen_lane_id "$BRIDGED_OUT_LANE_POS" "$BRIDGED_CHAIN_POS" "$THIS_IN_LANE_POS" "$THIS_CHAIN_POS")
OUTLANE_ID=$(seth --to-uint256 $OUTLANE_ID)
INLANE_ID=$(seth --to-uint256 $INLANE_ID)

CHAINMESSAGECOMMITTER_THIS_CHAIN_POSITION=$(seth call "$ChainMessageCommitter" 'THIS_CHAIN_POSITION()(uint)' --chain $SOURCE_CHAIN)
CHAINMESSAGECOMMITTER_MAXCHAINPOSITION=$(seth call "$ChainMessageCommitter" 'maxChainPosition()(uint)' --chain $SOURCE_CHAIN)
CHAINMESSAGECOMMITTER_LEAVE_1=$(seth call "$ChainMessageCommitter" 'leaveOf(uint)(address)' "$BRIDGED_CHAIN_POS" --chain $SOURCE_CHAIN)
check  "CHAINMESSAGECOMMITTER_THIS_CHAIN_POSITION"  "THIS_CHAIN_POS"
check  "CHAINMESSAGECOMMITTER_MAXCHAINPOSITION"     "BRIDGED_CHAIN_POS"
check  "CHAINMESSAGECOMMITTER_LEAVE_1"              "LaneMessageCommitter"

LANEMESSAGECOMMITTER_THIS_CHAIN_POSITION=$(seth call "$LaneMessageCommitter" 'THIS_CHAIN_POSITION()(uint)' --chain $SOURCE_CHAIN)
LANEMESSAGECOMMITTER_BRIDGED_CHAIN_POSITION=$(seth call "$LaneMessageCommitter" 'BRIDGED_CHAIN_POSITION()(uint)' --chain $SOURCE_CHAIN)
LANEMESSAGECOMMITTER_LEAVE_0=$(seth call "$LaneMessageCommitter" 'leaveOf(uint)(address)' 0 --chain $SOURCE_CHAIN)
LANEMESSAGECOMMITTER_LEAVE_1=$(seth call "$LaneMessageCommitter" 'leaveOf(uint)(address)' 1 --chain $SOURCE_CHAIN)
check  "LANEMESSAGECOMMITTER_THIS_CHAIN_POSITION"     "THIS_CHAIN_POS"
check  "LANEMESSAGECOMMITTER_BRIDGED_CHAIN_POSITION"  "BRIDGED_CHAIN_POS"
check  "LANEMESSAGECOMMITTER_LEAVE_0"                 "SerialOutboundLane"
check  "LANEMESSAGECOMMITTER_LEAVE_1"                 "SerialInboundLane"

LATEST_RECEIVED_NONCE=1
LATEST_GENERATED_NONCE=0
OLDEST_UNPRUNED_NONCE=0
SERIALOUTBOUNDLANE_LANE_INFO=$(seth call "$SerialOutboundLane" 'getLaneInfo()(uint32,uint32,uint32,uint32)' --chain $SOURCE_CHAIN)
SERIALOUTBOUNDLANE_NONCE_INFO=$(seth call "$SerialOutboundLane" 'outboundLaneNonce()(uint64,uint64,uint64)' --chain $SOURCE_CHAIN)
SERIALOUTBOUNDLANE_LANE_ID=$(seth call "$SerialOutboundLane" 'getLaneId()' --chain $SOURCE_CHAIN)
SERIALOUTBOUNDLANE_FEE_MARKET=$(seth call "$SerialOutboundLane" 'FEE_MARKET()(address)' --chain $SOURCE_CHAIN)
SERIALOUTBOUNDLANE_THIS_CHAIN_POS=$(echo $SERIALOUTBOUNDLANE_LANE_INFO          | cut -d' ' -f 1)
SERIALOUTBOUNDLANE_THIS_LANE_POS=$(echo $SERIALOUTBOUNDLANE_LANE_INFO           | cut -d' ' -f 2)
SERIALOUTBOUNDLANE_BRIDGED_CHAIN_POS=$(echo $SERIALOUTBOUNDLANE_LANE_INFO       | cut -d' ' -f 3)
SERIALOUTBOUNDLANE_BRIDGED_LANE_POS=$(echo $SERIALOUTBOUNDLANE_LANE_INFO        | cut -d' ' -f 4)
SERIALOUTBOUNDLANE_LATEST_RECEIVED_NONCE=$(echo $SERIALOUTBOUNDLANE_NONCE_INFO  | cut -d' ' -f 1)
SERIALOUTBOUNDLANE_LATEST_GENERATED_NONCE=$(echo $SERIALOUTBOUNDLANE_NONCE_INFO | cut -d' ' -f 2)
SERIALOUTBOUNDLANE_OLDEST_UNPRUNED_NONCE=$(echo $SERIALOUTBOUNDLANE_NONCE_INFO  | cut -d' ' -f 3)
check  "SERIALOUTBOUNDLANE_LANE_ID"                 "OUTLANE_ID"
check  "SERIALOUTBOUNDLANE_THIS_LANE_POS"           "THIS_CHAIN_POS"
check  "SERIALOUTBOUNDLANE_THIS_LANE_POS"           "THIS_OUT_LANE_POS"
check  "SERIALOUTBOUNDLANE_BRIDGED_CHAIN_POS"       "BRIDGED_CHAIN_POS"
check  "SERIALOUTBOUNDLANE_BRIDGED_LANE_POS"        "BRIDGED_IN_LANE_POS"
check  "SERIALOUTBOUNDLANE_FEE_MARKET"              "FeeMarketProxy"
check  "SERIALOUTBOUNDLANE_LATEST_RECEIVED_NONCE"   "LATEST_RECEIVED_NONCE"
check  "SERIALOUTBOUNDLANE_LATEST_GENERATED_NONCE"  "LATEST_GENERATED_NONCE"
check  "SERIALOUTBOUNDLANE_OLDEST_UNPRUNED_NONCE"   "OLDEST_UNPRUNED_NONCE"

LAST_CONFIRMED_NONCE=0
LAST_DELIVERED_NONCE=0
RELAYER_RANGE_FRONT=1
RELAYER_RANGE_BACK=0
SERIALINBOUNDLANE_LANE_INFO=$(seth call "$SerialInboundLane" 'getLaneInfo()(uint32,uint32,uint32,uint32)' --chain $SOURCE_CHAIN)
SERIALINBOUNDLANE_NONCE_INFO=$(seth call "$SerialInboundLane" 'inboundLaneNonce()(uint64,uint64,uint64,uint64)' --chain $SOURCE_CHAIN)
SERIALINBOUNDLANE_LANE_ID=$(seth call "$SerialInboundLane" 'getLaneId()' --chain $SOURCE_CHAIN)
SERIALINBOUNDLANE_MAX_GAS_PER_MESSAGE=$(seth call "$SerialInboundLane" 'MAX_GAS_PER_MESSAGE()(uint)' --chain $SOURCE_CHAIN)
SERIALINBOUNDLANE_THIS_CHAIN_POS=$(echo $SERIALINBOUNDLANE_LANE_INFO        | cut -d' ' -f 1)
SERIALINBOUNDLANE_THIS_LANE_POS=$(echo $SERIALINBOUNDLANE_LANE_INFO         | cut -d' ' -f 2)
SERIALINBOUNDLANE_BRIDGED_CHAIN_POS=$(echo $SERIALINBOUNDLANE_LANE_INFO     | cut -d' ' -f 3)
SERIALINBOUNDLANE_BRIDGED_LANE_POS=$(echo $SERIALINBOUNDLANE_LANE_INFO      | cut -d' ' -f 4)
SERIALINBOUNDLANE_LAST_CONFIRMED_NONCE=$(echo $SERIALINBOUNDLANE_NONCE_INFO | cut -d' ' -f 1)
SERIALINBOUNDLANE_LAST_DELIVERED_NONCE=$(echo $SERIALINBOUNDLANE_NONCE_INFO | cut -d' ' -f 2)
SERIALINBOUNDLANE_RELAYER_RANGE_FRONT=$(echo $SERIALINBOUNDLANE_NONCE_INFO  | cut -d' ' -f 3)
SERIALINBOUNDLANE_RELAYER_RANGE_BACK=$(echo $SERIALINBOUNDLANE_NONCE_INFO   | cut -d' ' -f 4)
check  "SERIALINBOUNDLANE_LANE_ID"               "INLANE_ID"
check  "SERIALINBOUNDLANE_THIS_LANE_POS"         "THIS_CHAIN_POS"
check  "SERIALINBOUNDLANE_THIS_LANE_POS"         "THIS_IN_LANE_POS"
check  "SERIALINBOUNDLANE_BRIDGED_CHAIN_POS"     "BRIDGED_CHAIN_POS"
check  "SERIALINBOUNDLANE_BRIDGED_LANE_POS"      "BRIDGED_OUT_LANE_POS"
check  "SERIALINBOUNDLANE_MAX_GAS_PER_MESSAGE"   "MAX_GAS_PER_MESSAGE"
check  "SERIALINBOUNDLANE_LAST_CONFIRMED_NONCE"  "LAST_CONFIRMED_NONCE"
check  "SERIALINBOUNDLANE_LAST_DELIVERED_NONCE"  "LAST_DELIVERED_NONCE"
check  "SERIALINBOUNDLANE_RELAYER_RANGE_FRONT"   "RELAYER_RANGE_FRONT"
check  "SERIALINBOUNDLANE_RELAYER_RANGE_BACK"    "RELAYER_RANGE_BACK"

ORACLE=$(load_conf ".Oracle.${TARGET_CHAIN}")

# check ArbitrumSerialLaneVerifier
CHANGABLE="true"
LANE_NONCE_SLOT=1
LANE_MESSAGE_SLOT=2
ARBITRUMSERIALLANEVERIFIER_LIGHT_CLIENT=$(seth call "$ArbitrumSerialLaneVerifier" 'LIGHT_CLIENT()(address)' --chain $SOURCE_CHAIN)
ARBITRUMSERIALLANEVERIFIER_CHANGABLE=$(seth call "$ArbitrumSerialLaneVerifier" 'changable()(bool)' --chain $SOURCE_CHAIN)
ARBITRUMSERIALLANEVERIFIER_THIS_CHAIN_POSITION=$(seth call "$ArbitrumSerialLaneVerifier" 'THIS_CHAIN_POSITION()(uint)' --chain $SOURCE_CHAIN)
ARBITRUMSERIALLANEVERIFIER_LANE_NONCE_SLOT=$(seth call "$ArbitrumSerialLaneVerifier" 'LANE_NONCE_SLOT()(uint)' --chain $SOURCE_CHAIN)
ARBITRUMSERIALLANEVERIFIER_LANE_MESSAGE_SLOT=$(seth call "$ArbitrumSerialLaneVerifier" 'LANE_MESSAGE_SLOT()(uint)' --chain $SOURCE_CHAIN)
check  "ARBITRUMSERIALLANEVERIFIER_LIGHT_CLIENT"       "ORACLE"
check  "ARBITRUMSERIALLANEVERIFIER_CHANGABLE"          "CHANGABLE"
check  "ARBITRUMSERIALLANEVERIFIER_LANE_NONCE_SLOT"    "LANE_NONCE_SLOT"
check  "ARBITRUMSERIALLANEVERIFIER_LANE_MESSAGE_SLOT"  "LANE_MESSAGE_SLOT"
