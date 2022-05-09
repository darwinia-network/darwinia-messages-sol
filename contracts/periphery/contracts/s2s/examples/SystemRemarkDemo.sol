// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../CrabSmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";

contract SystemRemarkDemo is CrabSmartChainXApp {

    function systemRemark() public payable {
        // 1. prepare the call that will be executed on the target chain
        System.RemarkCall memory call = System.RemarkCall(
            hex"0001",
            hex"12345678"
        );
        bytes memory callEncoded = System.encodeRemarkCall(call);

        // 2. send the message
        sendMessageToDarwinia(
            200000000000000000000, // deliveryAndDispatchFee
            2654000000, // call weight
            callEncoded // call encoded bytes
        );
    }
    
}
