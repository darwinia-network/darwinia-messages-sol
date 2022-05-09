// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";

contract RemarkDemo is SmartChainXApp {

    constructor() public {
        setLane(0, 0x3003, 0);
    }

    function remark() public payable {
        // 1. prepare the call that will be executed on the target chain
        System.RemarkCall memory call = System.RemarkCall(
            hex"0001",
            hex"12345678"
        );
        bytes memory callEncoded = System.encodeRemarkCall(call);

        // 2. send the message
        sendMessage(
            0,
            200000000000000000000, // deliveryAndDispatchFee
            1200, // spec version of target chain
            2654000000, // call weight
            callEncoded // call encoded bytes
        );
    }
    
}
