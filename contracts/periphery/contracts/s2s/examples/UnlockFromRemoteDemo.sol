// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";

// PangolinSmartChain remote call unlockFromRemote of Pangoro
contract UnlockFromRemoteDemo is SmartChainXApp {
    constructor() public {
        setConfig(Config(
            0x0000000000000000000000000000000000000019, // dispatch address
            0x2b03, // dispatch call index
            0x000000000000000000000000000000000000001a // storage address
        ));

        addBridge(0, BridgeConfig(
            hex"190d00dd4103825c78f55e5b5dbf8bfe2edb70953213f33a6ef6b8a5e3ffcab2", // storage key for Pangoro market fee
            0 // lane id, lane to Pangoro
        ));
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
        sendMessage(
            0, // lane id, the lane to Pangoro
            payload // message payload
        );
    }

}
