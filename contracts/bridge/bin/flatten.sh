#!/usr/bin/env bash

set -ex

rm -rf flat/
mkdir -p flat

hevm flatten --source-file src/fee-market/FeeMarket.sol                          --json-file out/dapp.sol.json > flat/FeeMarket.f.sol
hevm flatten --source-file src/fee-market/SimpleFeeMarket.sol                    --json-file out/dapp.sol.json > flat/SimpleFeeMarket.f.sol
hevm flatten --source-file src/message/SerialInboundLane.sol                     --json-file out/dapp.sol.json > flat/SerialInboundLane.f.sol
hevm flatten --source-file src/message/ParallelInboundLane.sol                   --json-file out/dapp.sol.json > flat/ParallelInboundLane.f.sol
hevm flatten --source-file src/message/SerialOutboundLane.sol                    --json-file out/dapp.sol.json > flat/SerialOutboundLane.f.sol
hevm flatten --source-file src/message/ParallelOutboundLane.sol                  --json-file out/dapp.sol.json > flat/ParallelOutboundLane.f.sol
hevm flatten --source-file src/proxy/fee-market/FeeMarketProxy.sol               --json-file out/dapp.sol.json > flat/FeeMarketProxy.f.sol
hevm flatten --source-file src/proxy/truth/ChainMessageCommitterProxy.sol        --json-file out/dapp.sol.json > flat/ChainMessageCommitterProxy.f.sol
hevm flatten --source-file src/proxy/BridgeProxyAdmin.sol                        --json-file out/dapp.sol.json > flat/BridgeProxyAdmin.f.sol
hevm flatten --source-file src/truth/bsc/BSCLightClient.sol                      --json-file out/dapp.sol.json > flat/BSCLightClient.f.sol
hevm flatten --source-file src/truth/bsc/BSCSerialLaneVerifier.sol               --json-file out/dapp.sol.json > flat/BSCSerialLaneVerifier.f.sol
hevm flatten --source-file src/truth/darwinia/ChainMessageCommitter.sol          --json-file out/dapp.sol.json > flat/ChainMessageCommitter.f.sol
hevm flatten --source-file src/truth/darwinia/DarwiniaMessageVerifier.sol        --json-file out/dapp.sol.json > flat/DarwiniaMessageVerifier.f.sol
hevm flatten --source-file src/truth/darwinia/LaneMessageCommitter.sol           --json-file out/dapp.sol.json > flat/LaneMessageCommitter.f.sol
hevm flatten --source-file src/truth/darwinia/POSALightClient.sol                --json-file out/dapp.sol.json > flat/POSALightClient.f.sol
hevm flatten --source-file src/truth/eth/BeaconLightClient.sol                   --json-file out/dapp.sol.json > flat/BeaconLightClient.f.sol
hevm flatten --source-file src/truth/eth/EthereumSerialLaneVerifier.sol          --json-file out/dapp.sol.json > flat/EthereumSerialLaneVerifier.f.sol
hevm flatten --source-file src/truth/eth/EthereumParallelLaneStorageVerifier.sol --json-file out/dapp.sol.json > flat/EthereumParallelLaneStorageVerifier.f.sol
hevm flatten --source-file src/truth/eth/BeaconLCMandatoryReward.sol             --json-file out/dapp.sol.json > flat/BeaconLCMandatoryReward.f.sol
hevm flatten --source-file src/truth/arbitrum/ArbitrumFeedOracle.sol             --json-file out/dapp.sol.json > flat/ArbitrumFeedOracle.f.sol
hevm flatten --source-file src/truth/arbitrum/ArbitrumRequestOracle.sol          --json-file out/dapp.sol.json > flat/ArbitrumRequestOracle.f.sol
hevm flatten --source-file src/truth/arbitrum/ArbitrumSerialLaneVerifier.sol     --json-file out/dapp.sol.json > flat/ArbitrumSerialLaneVerifier.f.sol
hevm flatten --source-file src/truth/arbitrum/ArbitrumRequestOracle.sol          --json-file out/dapp.sol.json > flat/ArbitrumRequestOracle.f.sol
hevm flatten --source-file src/oracle/AirnodeRrpRequester.sol                    --json-file out/dapp.sol.json > flat/AirnodeRrpRequester.f.sol
