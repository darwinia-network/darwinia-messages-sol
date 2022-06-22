// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

// The base contract for developers to inherit
abstract contract SmartChainXApp {
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

    bytes4 public srcChainId = 0;

    // Precompile address for getting state storage
    // The address is used to get market fee.
    address public storageAddress = address(1024);

    // Precompile address for dispatching 'send_message'
    address public dispatchAddress = address(1025);

    // Message sender address on the source chain.
    // It will be used on the target chain.
    // It should be updated after the dapp is deployed on the source chain.
    // See more details in the 'deriveSenderFromRemote' below.
    address public remoteSender;

    /// @notice Send message over lane id
    /// @param bridgeConfig The bridge config
    /// @param laneId The outlane id
    /// @param payload The message payload to be sent
    /// @return nonce The nonce of the message
    function sendMessage(
        BridgeConfig memory bridgeConfig,
        bytes4 laneId,
        MessagePayload memory payload
    ) internal returns (uint64) {
        // Get the current market fee
        uint128 fee = SmartChainXLib.marketFee(
            storageAddress,
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
            dispatchAddress,
            bridgeConfig.callIndexOfSendMessage,
            laneId,
            msg.value,
            message
        );

        // Get nonce from storage
        return
            SmartChainXLib.latestNonce(
                storageAddress,
                bridgeConfig.srcStorageKeyForLatestNonce,
                laneId
            );
    }

    /// @notice Determine if the `sender` is derived from remote.
    ///
    ///    // Add this 'require' to your function on the target chain which will be called
    ///    require(
    ///         derivedFromRemote(msg.sender),
    ///        "msg.sender is not derived from remote"
    ///    );
    ///
    /// @return bool Does the sender address authorized?
    function derivedFromRemote(address sender) internal view returns (bool) {
        return
            sender ==
            SmartChainXLib.deriveSenderFromRemote(
                srcChainId,
                remoteSender
            );
    }
}
