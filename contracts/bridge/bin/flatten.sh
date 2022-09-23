#!/usr/bin/env bash

set -ex

rm -rf flat/
mkdir -p flat

hevm flatten --source-file src/fee-market/FeeMarket.sol                    --json-file out/dapp.sol.json > flat/FeeMarket.f.sol
hevm flatten --source-file src/fee-market/SimpleFeeMarket.sol              --json-file out/dapp.sol.json > flat/SimpleFeeMarket.f.sol
hevm flatten --source-file src/message/InboundLane.sol                     --json-file out/dapp.sol.json > flat/InboundLane.f.sol
hevm flatten --source-file src/message/OutboundLane.sol                    --json-file out/dapp.sol.json > flat/OutboundLane.f.sol
hevm flatten --source-file src/proxy/fee-market/FeeMarketProxy.sol         --json-file out/dapp.sol.json > flat/FeeMarketProxy.f.sol
hevm flatten --source-file src/proxy/truth/ChainMessageCommitterProxy.sol  --json-file out/dapp.sol.json > flat/ChainMessageCommitterProxy.f.sol
hevm flatten --source-file src/proxy/BridgeProxyAdmin.sol                  --json-file out/dapp.sol.json > flat/BridgeProxyAdmin.f.sol
hevm flatten --source-file src/truth/bsc/BSCLightClient.sol                --json-file out/dapp.sol.json > flat/BSCLightClient.f.sol
hevm flatten --source-file src/truth/bsc/BSCStorageVerifier.sol            --json-file out/dapp.sol.json > flat/BSCStorageVerifier.f.sol
hevm flatten --source-file src/truth/darwinia/ChainMessageCommitter.sol    --json-file out/dapp.sol.json > flat/ChainMessageCommitter.f.sol
hevm flatten --source-file src/truth/darwinia/DarwiniaMessageVerifier.sol  --json-file out/dapp.sol.json > flat/DarwiniaMessageVerifier.f.sol
hevm flatten --source-file src/truth/darwinia/LaneMessageCommitter.sol     --json-file out/dapp.sol.json > flat/LaneMessageCommitter.f.sol
hevm flatten --source-file src/truth/darwinia/POSALightClient.sol          --json-file out/dapp.sol.json > flat/POSALightClient.f.sol
hevm flatten --source-file src/truth/eth/BeaconLightClient.sol             --json-file out/dapp.sol.json > flat/BeaconLightClient.f.sol
hevm flatten --source-file src/truth/eth/EthereumStorageVerifier.sol       --json-file out/dapp.sol.json > flat/EthereumStorageVerifier.f.sol
hevm flatten --source-file src/truth/eth/ExecutionLayer.sol                --json-file out/dapp.sol.json > flat/ExecutionLayer.f.sol
hevm flatten --source-file src/truth/eth/BeaconLCMandatoryReward.sol       --json-file out/dapp.sol.json > flat/BeaconLCMandatoryReward.f.sol
