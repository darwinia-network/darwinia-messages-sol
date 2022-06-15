// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

// CrabSmartChain remote call remark of Darwinia
abstract contract CrabXApp is SmartChainXApp, Ownable {
    function init() internal {
        dispatchAddress = 0x0000000000000000000000000000000000000019;
        callIndexOfSendMessage = 0x2b03;
        storageAddress = 0x000000000000000000000000000000000000001a;
        callbackSender = 0x6461722f64766D70000000000000000000000000;
    }

    BridgeConfig internal toDarwinia = BridgeConfig(
        // outlane id, lane to Darwinia
        0,
        // storage key for Darwinia market fee 
        hex"190d00dd4103825c78f55e5b5dbf8bfe2edb70953213f33a6ef6b8a5e3ffcab2",
        // storage key for the latest nonce of Darwinia message lane
        hex"c9b76e645ba80b6ca47619d64cb5e58d96c246acb9b55077390e3ca723a0ca1f11d2df4e979aa105cf552e9544ebd2b500000000"
    );

    BridgeConfig internal toCrabParachain = BridgeConfig(
        0,
        hex"190d00dd4103825c78f55e5b5dbf8bfe2edb70953213f33a6ef6b8a5e3ffcab2",
        hex"c9b76e645ba80b6ca47619d64cb5e58d96c246acb9b55077390e3ca723a0ca1f11d2df4e979aa105cf552e9544ebd2b500000000"
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

    function onMessageDelivered(
        bytes4 lane,
        uint64 nonce,
        bool result
    ) external override virtual {
        require(
            msg.sender == callbackSender,
            "Only pallet address is allowed call 'onMessageDelivered'"
        );
        
    }
}