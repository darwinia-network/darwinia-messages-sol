// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

pragma experimental ABIEncoderV2;

// CrabSmartChain remote call remark of Darwinia
abstract contract PangolinXApp is SmartChainXApp, Ownable {
    function init() internal {
        srcChainId = 0;
        dispatchAddress = 0x0000000000000000000000000000000000000019;
        callIndexOfSendMessage = 0x2b03;
        storageAddress = 0x000000000000000000000000000000000000001a;
        callbackSender = 0x6461722f64766D70000000000000000000000000;
    }

    BridgeConfig internal toPangoro =
        BridgeConfig(
            0x7621b367d09b75f6876b13089ee0ded52edb70953213f33a6ef6b8a5e3ffcab2,
            0xc9b76e645ba80b6ca47619d64cb5e58d96c246acb9b55077390e3ca723a0ca1f
        );
    
     BridgeConfig internal toPangolinParachain =
        BridgeConfig(
            0x39bf2363dd0720bd6e11a4c86f4949322edb70953213f33a6ef6b8a5e3ffcab2,
            0xdcdffe6202217f0ecb0ec75d8a09b32c96c246acb9b55077390e3ca723a0ca1f
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

    function setToPangoro(BridgeConfig memory config) public onlyOwner {
        toPangoro = config;
    }

    function onMessageDelivered(
        bytes4 lane,
        uint64 nonce,
        bool result
    ) external override {
        require(
            msg.sender == callbackSender,
            "Only pallet address is allowed call 'onMessageDelivered'"
        );
    }
}