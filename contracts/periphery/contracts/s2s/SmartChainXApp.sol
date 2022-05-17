// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

abstract contract SmartChainXApp {
    struct Config {
        // config for dispatch call
        address dispatchAddress;
        bytes2 dispatchCallIndex;
        // config for market fee
        address storageAddress;
    }

    struct BridgeConfig {
        bytes storageKeyForMarketFee;
        bytes4 laneId;
    }

    struct MessagePayload {
        uint32 specVersionOfTargetChain;
        uint64 callWeight;
        bytes callEncoded;
    }

    Config config;
    // bridge id => BridgeConfig
    mapping(uint16 => BridgeConfig) bridgeConfigs;

    // Send message over lane.
    function sendMessage(
        uint16 bridgeId,
        MessagePayload memory payload
    ) internal {
        uint128 fee = SmartChainXLib.marketFee(
            config.storageAddress,
            bridgeConfigs[bridgeId].storageKeyForMarketFee
        );

        require(msg.value >= fee, "Not enough fee to pay");

        bytes memory message = SmartChainXLib.buildMessage(
            payload.specVersionOfTargetChain,
            payload.callWeight,
            payload.callEncoded
        );

        SmartChainXLib.sendMessage(
            config.dispatchAddress,
            config.dispatchCallIndex,
            bridgeConfigs[bridgeId].laneId,
            msg.value,
            message
        );
    }

    function setConfig(
        Config memory _config
    ) internal {
        config = _config;
    }

    function addBridge(uint16 bridgeId, BridgeConfig memory bridgeConfig) internal {
        bridgeConfigs[bridgeId] = bridgeConfig;
    }
}
