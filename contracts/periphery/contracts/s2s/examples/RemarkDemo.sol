// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";

// CrabSmartChain remote call remark of Darwinia 
contract RemarkDemo is SmartChainXApp {
    constructor() public {
        set(Vars(
            0x0000000000000000000000000000000000000019, // dispatch address
            0x3003, // dispatch call index
            0x000000000000000000000000000000000000001a, // storage address
            hex"190d00dd4103825c78f55e5b5dbf8bfe2edb70953213f33a6ef6b8a5e3ffcab2" // storage key for Darwinia market fee
        ));
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
        sendMessage(
            0, // lane id, the lane to Darwinia
            payload // message payload
        );
    }
}
