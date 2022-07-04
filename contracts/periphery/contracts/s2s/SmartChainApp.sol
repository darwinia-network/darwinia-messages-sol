// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

// The base contract for developers to inherit
abstract contract SmartChainApp {
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

    struct BridgeConfig {
        // Call index of 'send_message'
        bytes2 callIndexOfSendMessage;
        // The storage key used to get market fee
        bytes32 srcStorageKeyForMarketFee;
        // The storage key used to get latest nonce
        bytes32 srcStorageKeyForLatestNonce;
    }

    // Precompile address for getting state storage on the source chain
    address public srcStoragePrecompileAddress = address(1024);

    // Precompile address for dispatching 'send_message'
    address public srcDispatchPrecompileAddress = address(1025);

    ////////////////////////////////////
    // Internal functions
    ////////////////////////////////////

    /// @notice Send message over lane id
    /// @param bridgeConfig The bridge config
    /// @param outboundLaneId The outboundLane id
    /// @param payload The message payload to be sent
    /// @return nonce The nonce of the message
    function sendMessage(
        BridgeConfig memory bridgeConfig,
        bytes4 outboundLaneId,
        MessagePayload memory payload
    ) internal returns (uint64) {
        // Get the current market fee
        uint128 fee = SmartChainXLib.marketFee(
            srcStoragePrecompileAddress,
            bridgeConfig.srcStorageKeyForMarketFee
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
            srcDispatchPrecompileAddress,
            bridgeConfig.callIndexOfSendMessage,
            outboundLaneId,
            msg.value,
            message
        );

        // Get nonce from storage
        return
            SmartChainXLib.latestNonce(
                srcStoragePrecompileAddress,
                bridgeConfig.srcStorageKeyForLatestNonce,
                outboundLaneId
            );
    }
}
