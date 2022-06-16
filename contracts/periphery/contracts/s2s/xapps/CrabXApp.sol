// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

pragma experimental ABIEncoderV2;

// CrabSmartChain remote call remark of Darwinia
abstract contract CrabXApp is SmartChainXApp, Ownable {
    function init() internal {
        srcChainId = 0;
        dispatchAddress = 0x0000000000000000000000000000000000000019;
        callIndexOfSendMessage = 0x2b03;
        storageAddress = 0x000000000000000000000000000000000000001a;
        callbackSender = 0x6461722f64766D70000000000000000000000000;
    }

    BridgeConfig internal toDarwinia =
        BridgeConfig(
            0xe0c938a0fbc88db6078b53e160c7c3ed2edb70953213f33a6ef6b8a5e3ffcab2,
            0xf1501030816118b9129255f5096aa9b296c246acb9b55077390e3ca723a0ca1f
        );

    BridgeConfig internal toCrabParachain =
        BridgeConfig(
            0x190d00dd4103825c78f55e5b5dbf8bfe2edb70953213f33a6ef6b8a5e3ffcab2,
            0xc9b76e645ba80b6ca47619d64cb5e58d96c246acb9b55077390e3ca723a0ca1f
            0x2158e364c657788d669f15db7687496b2edb70953213f33a6ef6b8a5e3ffcab2,
            0xef3be8173575ddc682e1a72d92ce0b2696c246acb9b55077390e3ca723a0ca1f
        );

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

    function setCallbackFromAddresss(address _callbackFromAddress)
        public
        onlyOwner
    {
        callbackSender = _callbackFromAddress;
    }

    function setStorageAddress(address _storageAddress) public onlyOwner {
        storageAddress = _storageAddress;
    }

    function setMessageSenderOnSrcChain(address _messageSenderOnSrcChain)
        public
        onlyOwner
    {
        messageSenderOnSrcChain = _messageSenderOnSrcChain;
    }

    function setToDarwinia(BridgeConfig memory config) public onlyOwner {
        toDarwinia = config;
    }

    function setToCrabParachain(BridgeConfig memory config) public onlyOwner {
        toCrabParachain = config;
    }

    function onMessageDelivered(
        bytes4 lane,
        uint64 nonce,
        bool result
    ) external virtual override {
        require(
            msg.sender == callbackSender,
            "Only pallet address is allowed call 'onMessageDelivered'"
        );
    }
}
