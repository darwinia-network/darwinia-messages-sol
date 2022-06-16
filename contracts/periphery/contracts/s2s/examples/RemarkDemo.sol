// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../xapps/CrabXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

pragma experimental ABIEncoderV2;

// CrabSmartChain remote call remark of Darwinia
contract RemarkDemo is CrabXApp {
    event OutputNonce(uint256 nonce);

    constructor() public {
        init();
    }
    
    function remark() public payable {
        // 1. prepare the call that will be executed on the target chain
        System.RemarkCall memory call = System.RemarkCall(
            hex"0009", // the call index of remark_with_event
            hex"12345678"
        );
        bytes memory callEncoded = System.encodeRemarkCall(call);

        // 2. send the message
        MessagePayload memory payload = MessagePayload(
            1210, // spec version of target chain <----------- This may be changed, go to https://darwinia.subscan.io/runtime get the latest spec version
            2654000000, // call weight
            callEncoded // call encoded bytes
        );
        uint64 nonce = sendMessage(toDarwinia, payload);
        emit OutputNonce(nonce);
    }

    function onMessageDelivered(bytes4 lane, uint64 nonce, bool result) external override {
        require(
            msg.sender == callbackSender,
            "Only pallet address is allowed call 'onMessageDelivered'"
        );
        // TODO: Your code goes here...
    }
}
