// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

pragma experimental ABIEncoderV2;

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
        bytes32 storageKeyForMarketFee;
        // The storage key used to get latest nonce
        bytes storageKeyForLatestNonce;
        // The lane id
        bytes4 laneId;
    }

    // Precompile address for dispatching 'send_message'
    address internal dispatchAddress =
        0x0000000000000000000000000000000000000019;

    // Call index of 'send_message'
    bytes2 internal callIndexOfSendMessage = 0x3003;

    // Precompile address for getting state storage
    // The address is used to get market fee.
    address internal storageAddress =
        0x000000000000000000000000000000000000001a;

    // The 'onMessageDelivered' sender
    // 'onMessageDelivered' is only allowed to be called by this address
    address internal callbackFromAddress =
        0x6461722f64766D70000000000000000000000000;

    // Config of each bridge
    // bridge id => BridgeConfig
    mapping(uint16 => BridgeConfig) internal bridgeConfigs;

    // Send message over bridge id
    function sendMessage(uint16 bridgeId, MessagePayload memory payload)
        internal
        returns (uint64)
    {
        // Get the current market fee
        uint128 fee = SmartChainXLib.marketFee(
            storageAddress,
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
            dispatchAddress,
            callIndexOfSendMessage,
            bridgeConfigs[bridgeId].laneId,
            msg.value,
            message
        );

        // Get nonce from storage
        return
            SmartChainXLib.latestNonce(
                storageAddress,
                bridgeConfigs[bridgeId].storageKeyForLatestNonce
            );
    }

    function getDispatchAddress() public view returns (address) {
        return dispatchAddress;
    }

    function getCallIndexOfSendMessage() public view returns (bytes2) {
        return callIndexOfSendMessage;
    }

    function getStorageAddress() public view returns (address) {
        return storageAddress;
    }

    function getCallbackFromAddress() public view returns (address) {
        return callbackFromAddress;
    }

    function getBridgeConfig(uint16 bridgeId)
        public
        view
        returns (bytes32, bytes4)
    {
        BridgeConfig memory config = bridgeConfigs[bridgeId];
        return (config.storageKeyForMarketFee, config.laneId);
    }

    /// @notice Message delivered callback
    /// @param lane Lane id
    /// @param nonce Nonce of the callback message
    /// @param result Dispatch result of cross chain message
    function onMessageDelivered(
        bytes4 lane,
        uint64 nonce,
        bool result
    ) external virtual;
}
