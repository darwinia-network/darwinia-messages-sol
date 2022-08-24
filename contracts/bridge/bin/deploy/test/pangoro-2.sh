#!/usr/bin/env bash

set -e

export NETWORK_NAME=pangoro
export TARGET_CHAIN=bsctest
# export ETH_RPC_URL=https://pangoro-rpc.darwinia.network
export ETH_RPC_URL=http://35.247.165.91:9933

echo "ETH_FROM: ${ETH_FROM}"

. $(dirname $0)/base.sh
load-addresses

# darwinia to bsc bridge config
this_chain_pos=0
this_out_lane_pos=0
this_in_lane_pos=1
bridged_chain_pos=2
bridged_in_lane_pos=1
bridged_out_lane_pos=0

# fee market config
FEEMARKET_VAULT=$ETH_FROM
COLLATERAL_PERORDER=$(seth --to-wei 10 ether)
ASSIGNED_RELAYERS_NUMBER=3
SLASH_TIME=86400
RELAY_TIME=86400
# 0.01 : 300
PRICE_RATIO=999900

FeeMarket=$(deploy FeeMarket \
  $FEEMARKET_VAULT \
  $COLLATERAL_PERORDER \
  $ASSIGNED_RELAYERS_NUMBER \
  $SLASH_TIME $RELAY_TIME \
  $PRICE_RATIO)

sig="initialize(address)"
data=$(seth calldata $sig $ETH_FROM)
FeeMarketProxy=$(deploy FeeMarketProxy \
  $FeeMarket \
  $BridgeProxyAdmin \
  $data)

# bsc light client config
block_number=21791400
block_header=$(seth block $block_number --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545
)
parent_hash=$(echo "$block_header" | seth --field parentHash)
uncle_hash=$(echo "$block_header" | seth --field sha3Uncles)
coinbase=$(echo "$block_header" | seth --field miner)
state_root=$(echo "$block_header" | seth --field stateRoot)
transactions_root=$(echo "$block_header" | seth --field transactionsRoot)
receipts_root=$(echo "$block_header" | seth --field receiptsRoot)
log_bloom=$(echo "$block_header" | seth --field logsBloom)
difficulty=$(seth --to-uint256 $(echo "$block_header" | seth --field difficulty))
number=$(seth --to-uint256 $(echo "$block_header" | seth --field number))
gas_limit=$(seth --to-uint256 $(echo "$block_header" | seth --field gasLimit))
gas_used=$(seth --to-uint256 $(echo "$block_header" | seth --field gasUsed))
timestamp=$(seth --to-uint256 $(echo "$block_header" | seth --field timestamp))
extra_data=$(echo "$block_header" | seth --field extraData)
mix_digest=$(echo "$block_header" | seth --field mixHash)
nonce=$(seth --to-uint64 $(echo "$block_header" | seth --field nonce))

DATA=$(set -x; ethabi encode params \
  -v "address" ${ETH_FROM:2} \
  -v "(bytes32,bytes32,address,bytes32,bytes32,bytes32,bytes,uint256,uint256,uint64,uint64,uint64,bytes,bytes32,bytes8)" \
  "(${parent_hash:2},${uncle_hash:2},${coinbase:2},${state_root:2},${transactions_root:2},${receipts_root:2},${log_bloom:2},${difficulty:2},${number:2},${gas_limit:2},${gas_used:2},${timestamp:2},${extra_data:2},${mix_digest:2},${nonce:2})")

chain_id=$(seth chain-id --chain $TARGET_CHAIN)
period=3
BSCLightClient=$(deploy BSCLightClient $chain_id $period)
SIG=$(set -x; cast sig "initialize(address,(bytes32,bytes32,address,bytes32,bytes32,bytes32,bytes,uint256,uint256,uint64,uint64,uint64,bytes,bytes32,bytes8))")
BSCLightClientProxy=$(deploy BSCLightClientProxy \
  $BSCLightClient \
  $BridgeProxyAdmin \
  $SIG$DATA)


OutboundLane=$(deploy OutboundLane \
  $BSCLightClientProxy \
  $FeeMarketProxy \
  $this_chain_pos \
  $this_out_lane_pos \
  $bridged_chain_pos \
  $bridged_in_lane_pos 1 0 0)

InboundLane=$(deploy InboundLane \
  $BSCLightClientProxy \
  $this_chain_pos \
  $this_in_lane_pos \
  $bridged_chain_pos \
  $bridged_out_lane_pos 0 0)

LaneMessageCommitter=$(deploy LaneMessageCommitter $this_chain_pos $bridged_chain_pos)
seth send -F $ETH_FROM $LaneMessageCommitter "registry(address,address)" $OutboundLane $InboundLane
seth send -F $ETH_FROM $ChainMessageCommitterProxy "registry(address)" $LaneMessageCommitter

seth send -F $ETH_FROM $FeeMarketProxy "setOutbound(address,uint)" $OutboundLane 1
