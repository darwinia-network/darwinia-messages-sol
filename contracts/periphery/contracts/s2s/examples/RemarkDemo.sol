// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";

// CrabSmartChain remote call remark of Darwinia
contract RemarkDemo is SmartChainXApp, Ownable {
    constructor() public {
        // Globle settings
        // The SmartChainXApp has default globle settings

        // Bridge settings
        bridgeConfigs[0] = BridgeConfig(
            // storage key for Darwinia market fee
            0x190d00dd4103825c78f55e5b5dbf8bfe2edb70953213f33a6ef6b8a5e3ffcab2,
            // storage key for the latest nonce of Darwinia message lane
            hex"c9b76e645ba80b6ca47619d64cb5e58d96c246acb9b55077390e3ca723a0ca1f11d2df4e979aa105cf552e9544ebd2b500000000",
            // lane id, lane to Darwinia
            0
        );
    }

    // You need to consider providing set methods with permission control
    // if you want to make the settings upgradable
    function setDispatchAddress(address _dispatchAddress) public onlyOwner {
        dispatchAddress = _dispatchAddress;
    }

    function setCallIndexOfSendMessage(bytes2 _callIndexOfSendMessage)
        public
        onlyOwner
    {
        callIndexOfSendMessage = _callIndexOfSendMessage;
    }

    function setStorageAddress(address _storageAddress) public onlyOwner {
        storageAddress = _storageAddress;
    }

    function setBridgeConfig(
        uint16 bridgeId,
        bytes32 storageKeyForMarketFee,
        bytes memory storageKeyForLatestNonce,
        bytes4 laneId
    ) public onlyOwner {
        bridgeConfigs[bridgeId] = BridgeConfig(storageKeyForMarketFee, storageKeyForLatestNonce, laneId);
    }

    function remark() public payable {
        // 1. prepare the call that will be executed on the target chain
        System.RemarkCall memory call = System.RemarkCall(
            hex"0001",
            hex"12345678"
        );
        bytes memory callEncoded = System.encodeRemarkCall(call);

        // 2. send the message
        MessagePayload memory payload = MessagePayload(
            1200, // spec version of target chain <----------- This may be changed, go to https://darwinia.subscan.io/runtime get the latest spec version
            2654000000, // call weight
            callEncoded // call encoded bytes
        );
        uint64 nonce = sendMessage(
            0, // bridge id, which is the mapping key of bridgeConfigs
            payload // message payload
        );
    }

    function onMessageDelivered(bytes4 lane, uint64 nonce, bool result) external override {
        // TODO: add your code here if you want to do something after the message delivered
    }
}
