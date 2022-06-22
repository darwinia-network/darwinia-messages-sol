// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../xapps/PangoroXApp.sol";
import "../types/PalletEthereum.sol";

pragma experimental ABIEncoderV2;

// deploy on the target chain first, then deploy on the source chain
contract TransactDemo is PangoroXApp {
    constructor() public {
        init();
    }

    uint256 public number;

    ///////////////////////////////////////////
    // used on the source chain
    ///////////////////////////////////////////
    function callAddOnTargetChain() public payable {
        // 1. prepare the call that will be executed on the target chain
        PalletEthereum.MessageTransactCall memory call = PalletEthereum.MessageTransactCall(
            // the call index of message_transact
            0x2901,
            // the evm transaction to transact
            PalletEthereum.buildTransactionV2ForMessageTransact(
                600000, // gas limit
                0x50275d3F95E0F2FCb2cAb2Ec7A231aE188d7319d, // <----------- change to the contract address on the target chain
                hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002" // the add function bytes that will be called on the target chain, add(2)
            )
        );
        bytes memory callEncoded = PalletEthereum.encodeMessageTransactCall(call);

        // 2. send the message
        MessagePayload memory payload = MessagePayload(
            28110, // spec version of target chain <----------- go to https://pangolin.subscan.io/runtime get the latest spec version
            2654000000, // call weight
            callEncoded // call encoded bytes
        );
        bytes4 lane = 0;
        sendMessage(toPangolin, lane, payload);
    }

    ///////////////////////////////////////////
    // used on the target chain
    ///////////////////////////////////////////
    function add(uint256 _value) public {
        // the sender is only allowed to be called by the derived address 
        // of dapp address on the source chain.
        require(
            derivedFromRemote(msg.sender), 
            "msg.sender is not derived from remote"
        );
        number = number + _value;
    }
}
