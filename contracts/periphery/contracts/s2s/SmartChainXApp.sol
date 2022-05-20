// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

// The base contract for developers to inherit
abstract contract SmartChainXApp {
    struct Config {
        // Precompile address for dispatching 'send_message'
        address dispatchAddress;

        // Call index of 'send_message'
        bytes2 callIndexOfSendMessage;

        // Precompile address for getting state storage
        // The address is used to get market fee.
        address storageAddress;
    }

    struct BridgeConfig {
        // The storage key used to get market fee
        bytes storageKeyForMarketFee;

        // The lane id 
        bytes4 laneId;
    }

    struct MessagePayload {
        // The spec version of target chain
        // This is used to compare against the on-chain spec version before the call dispatch on target chain.
        uint32 specVersionOfTargetChain;

        // The call weight
		// We want passed weight to be at least equal to pre-dispatch weight of the call
		// because otherwise Calls may be dispatched at lower price.
        uint64 callWeight;

        // The scale encoded call to be executed on the target chain
        bytes callEncoded;
    }

    // Globle cross-chain config
    Config private config;

    // Config of each bridge
    // bridge id => BridgeConfig
    mapping(uint16 => BridgeConfig) private bridgeConfigs;

    // Send message over bridge id
    function sendMessage(
        uint16 bridgeId,
        MessagePayload memory payload
    ) internal {
        // Get the current market fee
        uint128 fee = SmartChainXLib.marketFee(
            config.storageAddress,
            bridgeConfigs[bridgeId].storageKeyForMarketFee
        );
        require(msg.value >= fee, "Not enough fee to pay");

        // Build the encoded message to be sent 
        bytes memory message = SmartChainXLib.buildMessage(
            payload.specVersionOfTargetChain,
            payload.callWeight,
            payload.callEncoded
        );

        // Send the message
        SmartChainXLib.sendMessage(
            config.dispatchAddress,
            config.callIndexOfSendMessage,
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
