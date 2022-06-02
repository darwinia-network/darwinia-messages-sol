// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";

// PangolinSmartChain remote call unlockFromRemote of Pangoro
contract UnlockFromRemoteDemo is SmartChainXApp {
    constructor() public {
        // Globle settings
        dispatchAddress = 0x0000000000000000000000000000000000000019;
        callIndexOfSendMessage = 0x2b03;
        storageAddress = 0x000000000000000000000000000000000000001a;
        callbackSender = 0x6461722f64766D70000000000000000000000000;
    }
    
    function unlockFromRemote() public payable {
        // 1. prepare the call that will be executed on the target chain
        S2SBacking.UnlockFromRemoteCall memory unlockFromRemotecall = S2SBacking
            .UnlockFromRemoteCall(
                hex"1402",
                0x6D6F646C64612f6272696e670000000000000000,
                100000,
                hex"d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d"
            );
        bytes memory callEncoded = S2SBacking.encodeUnlockFromRemoteCall(
            unlockFromRemotecall
        );

        // 2. send the message
        MessagePayload memory payload = MessagePayload(
            28110, // spec version of target chain <----------- This may be changed, go to https://pangoro.subscan.io/runtime get the latest spec version
            2654000000, // call weight
            callEncoded // call encoded bytes
        );
        uint64 nonce = sendMessage(
            // lane id, lane to Pangoro
            0,
            // storage key for Darwinia market fee
            hex"190d00dd4103825c78f55e5b5dbf8bfe2edb70953213f33a6ef6b8a5e3ffcab2",
            // storage key for the latest nonce of Darwinia message lane
            hex"c9b76e645ba80b6ca47619d64cb5e58d96c246acb9b55077390e3ca723a0ca1f11d2df4e979aa105cf552e9544ebd2b500000000",
            // the message payload
            payload
        );
    }

    function onMessageDelivered(bytes4 lane, uint64 nonce, bool result) external override {
        require(msg.sender == callbackSender, "Only pallet address is allowed to call 'onMessageDelivered'");
        // TODO: Your code goes here...
    }
}
