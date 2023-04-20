#!/usr/bin/env bash

set -e

# cast --calldata-decode "import_next_sync_committee(((uint64,uint64,bytes32,bytes32,bytes32),(bytes[512],bytes),(uint64,uint64,bytes32,bytes32,bytes32),bytes32[],(bytes32[2],bytes),bytes4,uint64),((bytes[512],bytes),bytes32[]))" $1

cast --calldata-decode "receive_messages_proof((uint64,(uint256,(address,address,bytes))[]),bytes,uint256)" $1

# ethabi decode params -t '(bytes[],bytes[],bytes[][])' $1
