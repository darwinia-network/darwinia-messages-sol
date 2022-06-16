// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../xapps/PangolinXApp.sol";
import "../types/PalletEthereum.sol";

pragma experimental ABIEncoderV2;

// deploy on the target chain first, then deploy on the source chain
contract RemoteTransactDemo is PangolinXApp {
    constructor() public {
        init();
    }

    uint256 public number;

    ///////////////////////////////////////////
    // used on the source chain
    ///////////////////////////////////////////
    function callAddOnTheTargetChain() public payable {
        // 1. prepare the call that will be executed on the target chain
        PalletEthereum.SubstrateTransactCall memory call = PalletEthereum
            .SubstrateTransactCall(
                // the call index of substrate_transact
                0x2902,
                // the address of the contract on the target chain
                0x50275d3F95E0F2FCb2cAb2Ec7A231aE188d7319d, // <------------------ change to the contract address on the target chain
                // the add function bytes that will be called on the target chain, add(2)
                hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002"
            );
        bytes memory callEncoded = PalletEthereum.encodeSubstrateTransactCall(
            call
        );

        // 2. send the message
        MessagePayload memory payload = MessagePayload(
            28110, // spec version of target chain <----------- This may be changed, go to https://pangoro.subscan.io/runtime get the latest spec version
            2654000000, // call weight
            callEncoded // call encoded bytes
        );
        sendMessage(toPangoro, payload);
    }

    ///////////////////////////////////////////
    // used on the target chain
    ///////////////////////////////////////////
    function add(uint256 _value) public {
        // this 'require' makes this function only be called by the dapp contract on the source chain
        require(
            msg.sender == deriveSenderFromRemote(),
            "msg.sender must equal to the address derived from the message sender address on the source chain"
        );
        number = number + _value;
    }
}
