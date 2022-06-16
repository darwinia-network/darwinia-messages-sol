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
        // The storage key used to get market fee
        bytes32 srcStorageKeyForMarketFee;
        // The storage key used to get latest nonce
        bytes32 srcStorageKeyForLatestNonce;
    }

    bytes4 public srcChainId = 0;

    // Precompile address for dispatching 'send_message'
    address public dispatchAddress = 0x0000000000000000000000000000000000000019;

    // Call index of 'send_message'
    bytes2 public callIndexOfSendMessage = 0x3003;

    // Precompile address for getting state storage
    // The address is used to get market fee.
    address public storageAddress = 0x000000000000000000000000000000000000001a;

    // The 'onMessageDelivered' sender
    // 'onMessageDelivered' is only allowed to be called by this address
    address public callbackSender = 0x6461722f64766D70000000000000000000000000;

    // Message sender address on the source chain.
    // It will be used on the target chain.
    // It should be updated after the dapp is deployed on the source chain.
    // See more details in the 'deriveSenderFromRemote' below.
    address public messageSenderOnSrcChain;

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
            callIndexOfSendMessage,
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

    /// @notice Derive the sender address from the sender address of the message on the source chain.
    ///
    ///    // Add this 'require' to your function on the target chain which will be called by the 'send_message'
    ///    // This 'require' makes your function only allowed be called by the dapp contract on the source chain
    ///    require(
    ///        msg.sender == deriveSenderFromRemote(),
    ///        "msg.sender must equal to the address derived from the message sender address on the source chain"
    ///    );
    ///
    /// @return address The sender address on the target chain
    function deriveSenderFromRemote() internal returns (address) {
        bytes32 derivedSubstrateAddress = AccountId.deriveSubstrateAddress(
            messageSenderOnSrcChain
        );
        bytes32 derivedAccountId = SmartChainXLib.deriveAccountId(
            srcChainId,
            derivedSubstrateAddress
        );
        return AccountId.deriveEthereumAddress(derivedAccountId);
    }

    /// @notice Callback function for 'send_message'
    /// @param lane Lane id
    /// @param nonce Nonce of the callback message
    /// @param result Dispatch result of cross chain message
    function onMessageDelivered(
        bytes4 lane,
        uint64 nonce,
        bool result
    ) external virtual;
}
