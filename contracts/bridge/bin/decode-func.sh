#!/usr/bin/env bash

set -e

cast --calldata-decode "import_next_sync_committee(((uint64,uint64,bytes32,bytes32,bytes32),(bytes[512],bytes),(uint64,uint64,bytes32,bytes32,bytes32),bytes32[],(bytes32[2],bytes),bytes4,uint64),((bytes[512],bytes),bytes32[]))" $1
