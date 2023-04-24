#!/usr/bin/env bash

set -eo pipefail

export SOURCE_CHAIN=${from:?"!from"}
export TARGET_CHAIN=${to:?"!to"}
export DAO=${dao?}

. $(dirname $0)/base.sh
. $(dirname $0)/auth-checker.sh

parse_relayers() {
  python3 -c "[
    print(hex(x)) for x in $1
  ]
  "
}
check_is_relayer() {
  local CHECK
  CHECK=$(seth call "$POSALightClient" 'is_relayer(address)(bool)' $1 --chain $SOURCE_CHAIN)

  printf "RLY: POSALightClient -> %s -> " "${1}"
  if [[ $(toLower "${CHECK}") == "true" ]]; then
    ok
  else
    notok
  fi
}

# load_addresses
# load_addresses $ADDRESSES_FILE $TARGET_CHAIN

echo "=== Ethereum Checker ==="

BridgeProxyAdmin=$(load_staddr "BridgeProxyAdmin")
FeeMarket=$(load_saddr "SimpleFeeMarket")
FeeMarketProxy=$(load_saddr "FeeMarketProxy")
POSALightClient=$(load_saddr "POSALightClient")
DarwiniaMessageVerifier=$(load_saddr "DarwiniaMessageVerifier")
SerialOutboundLane=$(load_saddr "SerialOutboundLane")
SerialInboundLane=$(load_saddr "SerialInboundLane")

EthereumSerialLaneVerifier=$(load_taddr "EthereumSerialLaneVerifier")

# auth check
check_admin   "FeeMarketProxy"   "BridgeProxyAdmin"
check_imp     "FeeMarketProxy"   "FeeMarket"
check_owner   "BridgeProxyAdmin" "DAO"
check_setter  "FeeMarketProxy"   "DAO"

# config check
# fee market config
COLLATERAL_PER_ORDER=$(load_conf ".FeeMarket.collateral_perorder")
SLASH_TIME=$(load_conf ".FeeMarket.slash_time")
RELAY_TIME=$(load_conf ".FeeMarket.relay_time")
PRICE_RATIO_NUMERATOR=$(load_conf ".FeeMarket.price_ratio")
DUTY_REWARD_RATIO=$(load_conf ".FeeMarket.duty_ratio")
FEEMARKET_SLASH_TIME=$(seth call "$FeeMarketProxy" 'SLASH_TIME()(uint)' --chain $SOURCE_CHAIN)
FEEMARKET_RELAY_TIME=$(seth call "$FeeMarketProxy" 'RELAY_TIME()(uint)' --chain $SOURCE_CHAIN)
FEEMARKET_PRICE_RATIO_NUMERATOR=$(seth call "$FeeMarketProxy" 'PRICE_RATIO_NUMERATOR()(uint)' --chain $SOURCE_CHAIN)
FEEMARKET_COLLATERAL_PER_ORDER=$(seth call "$FeeMarketProxy" 'COLLATERAL_PER_ORDER()(uint)' --chain $SOURCE_CHAIN)
FEEMARKET_DUTY_REWARD_RATIO=$(seth call "$FeeMarketProxy" 'DUTY_REWARD_RATIO()(uint)' --chain $SOURCE_CHAIN)
check  "FEEMARKET_SLASH_TIME"            "SLASH_TIME"
check  "FEEMARKET_RELAY_TIME"            "RELAY_TIME"
check  "FEEMARKET_PRICE_RATIO_NUMERATOR" "PRICE_RATIO_NUMERATOR"
check  "FEEMARKET_COLLATERAL_PER_ORDER"  "COLLATERAL_PER_ORDER"
check  "FEEMARKET_DUTY_REWARD_RATIO"     "DUTY_REWARD_RATIO"

# check darwinia to eth2.0 bridge config
THIS_CHAIN_POS=$(load_conf ".Chain.this_chain_pos")
THIS_OUT_LANE_POS=$(load_conf ".Chain.Lanes[0].lanes[0].this_lane_pos")
THIS_IN_LANE_POS=$(load_conf ".Chain.Lanes[0].lanes[1].this_lane_pos")
BRIDGED_CHAIN_POS=$(load_conf ".Chain.Lanes[0].bridged_chain_pos")
BRIDGED_IN_LANE_POS=$(load_conf ".Chain.Lanes[0].lanes[0].bridged_lane_pos")
BRIDGED_OUT_LANE_POS=$(load_conf ".Chain.Lanes[0].lanes[1].bridged_lane_pos")
OUTLANE_ID=$(gen_lane_id "$BRIDGED_IN_LANE_POS" "$BRIDGED_CHAIN_POS" "$THIS_OUT_LANE_POS" "$THIS_CHAIN_POS")
INLANE_ID=$(gen_lane_id "$BRIDGED_OUT_LANE_POS" "$BRIDGED_CHAIN_POS" "$THIS_IN_LANE_POS" "$THIS_CHAIN_POS")
OUTLANE_ID=$(seth --to-uint256 $OUTLANE_ID)
INLANE_ID=$(seth --to-uint256 $INLANE_ID)
MAX_GAS_PER_MESSAGE=$(load_conf ".Chain.Lanes[0].lanes[1].max_gas_per_message")
OUTLANE_ID=$(gen_lane_id "$BRIDGED_IN_LANE_POS" "$BRIDGED_CHAIN_POS" "$THIS_OUT_LANE_POS" "$THIS_CHAIN_POS")
INLANE_ID=$(gen_lane_id "$BRIDGED_OUT_LANE_POS" "$BRIDGED_CHAIN_POS" "$THIS_IN_LANE_POS" "$THIS_CHAIN_POS")
OUTLANE_ID=$(seth --to-uint256 $OUTLANE_ID)
INLANE_ID=$(seth --to-uint256 $INLANE_ID)

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

# check DarwiniaMessageVerifier
ZERO=0
ZERO_HASH="0x0000000000000000000000000000000000000000000000000000000000000000"
DARWINIAMESSAGEVERIFIER_LIGHT_CLIENT=$(seth call "$DarwiniaMessageVerifier" 'LIGHT_CLIENT()(address)' --chain $SOURCE_CHAIN)
DARWINIAMESSAGEVERIFIER_MESSAGE_ROOT=$(seth call "$DarwiniaMessageVerifier" 'message_root()(bytes32)' --chain $SOURCE_CHAIN)
check "DARWINIAMESSAGEVERIFIER_LIGHT_CLIENT" "POSALightClient"
check "DARWINIAMESSAGEVERIFIER_LIGHT_CLIENT" "ZERO_HASH"

# check POSALightClient
DOMAIN_SEPARATOR=$(load_conf ".LightClient.domain_separator")
RELAYERS=$(load_conf ".LightClient.relayers")
# TODO: check relayers
relayers="$(parse_relayers $RELAYERS)"
THRESHOLD=$(load_conf ".LightClient.threshold")
NONCE=$(load_conf ".LightClient.nonce")
POSALIGHTCLIENT_BLOCK_NUMBER=$(seth call "$POSALightClient" 'block_number()(uint)' --chain $SOURCE_CHAIN)
POSALIGHTCLIENT_MERKLE_ROOT=$(seth call "$POSALightClient" 'merkle_root()(bytes32)' --chain $SOURCE_CHAIN)
POSALIGHTCLIENT_NONCE=$(seth call "$POSALightClient" 'nonce()(uint)' --chain $SOURCE_CHAIN)
POSALIGHTCLIENT_THRESHOLD=$(seth call "$POSALightClient" 'get_threshold()(uint)' --chain $SOURCE_CHAIN)
check  "POSALIGHTCLIENT_BLOCK_NUMBER"  "ZERO"
check  "POSALIGHTCLIENT_MERKLE_ROOT"   "ZERO_HASH"
check  "POSALIGHTCLIENT_THRESHOLD"     "THRESHOLD"
check  "POSALIGHTCLIENT_NONCE"         "NONCE"
for r in $relayers
do
  check_is_relayer $r
done

# check EthereumSerialLaneVerifier
ETHEREUMSERIALLANEVERIFIER_LANES_OUT=$(seth call "$EthereumSerialLaneVerifier" 'lanes(uint)(address)' $OUTLANE_ID --chain $TARGET_CHAIN)
ETHEREUMSERIALLANEVERIFIER_LANES_IN=$(seth call "$EthereumSerialLaneVerifier" 'lanes(uint)(address)' $INLANE_ID --chain $TARGET_CHAIN)
check  "ETHEREUMSERIALLANEVERIFIER_LANES_OUT"  "SerialOutboundLane"
check  "ETHEREUMSERIALLANEVERIFIER_LANES_IN"   "SerialInboundLane"
