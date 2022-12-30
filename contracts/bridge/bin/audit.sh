#!/usr/bin/env bash

rm -rf audit/
mkdir -p audit

FIXED_PARAMS="--solc $SOLC --checklist --exclude naming-convention,dead-code"

slither flat/BeaconLightClient.f.sol $FIXED_PARAMS           > audit/BeaconLightClient.md
slither flat/BridgeProxyAdmin.f.sol $FIXED_PARAMS            > audit/BridgeProxyAdmin.md
slither flat/ChainMessageCommitter.f.sol $FIXED_PARAMS       > audit/ChainMessageCommitter.md
slither flat/ChainMessageCommitterProxy.f.sol $FIXED_PARAMS  > audit/ChainMessageCommitterProxy.md
slither flat/DarwiniaMessageVerifier.f.sol $FIXED_PARAMS     > audit/DarwiniaMessageVerifier.md
slither flat/EthereumStorageVerifier.f.sol $FIXED_PARAMS     > audit/EthereumStorageVerifier.md
slither flat/ExecutionLayer.f.sol $FIXED_PARAMS              > audit/ExecutionLayer.md
slither flat/FeeMarket.f.sol $FIXED_PARAMS                   > audit/FeeMarket.md
slither flat/FeeMarketProxy.f.sol $FIXED_PARAMS              > audit/FeeMarketProxy.md
slither flat/InboundLane.f.sol $FIXED_PARAMS                 > audit/InboundLane.md
slither flat/LaneMessageCommitter.f.sol $FIXED_PARAMS        > audit/LaneMessageCommitter.md
slither flat/OutboundLane.f.sol $FIXED_PARAMS                > audit/OutboundLane.md
slither flat/POSALightClient.f.sol $FIXED_PARAMS             > audit/POSALightClient.md
slither flat/SimpleFeeMarket.f.sol $FIXED_PARAMS             > audit/SimpleFeeMarket.md
