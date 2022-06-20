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

    ///////////////////////////////////////////
    // used on the source chain
    ///////////////////////////////////////////

    // used to track the evm tx nonce
    uint256 public nextEvmTxNonce = 0;

    function callAddOnTheTargetChain() public payable {
        // 1. prepare the call that will be executed on the target chain
        PalletEthereum.TransactCall memory call = PalletEthereum.TransactCall(
            // the call index of transact
            0x2902,
            // the evm transaction to transact
            PalletEthereum.buildTransactionV2(
                nextEvmTxNonce, // evm tx nonce
                1000000000, // gasPrice, get from the target chain
                600000, // gasLimit, get from the target chain
                0x50275d3F95E0F2FCb2cAb2Ec7A231aE188d7319d, // <------------------ change to the contract address on the target chain
                0, // value, now the only allowed value is 0, or the tx will fail
                hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002" // the add function bytes that will be called on the target chain, add(2)
            )
        );
        bytes memory callEncoded = PalletEthereum.encodeTransactCall(call);

        // 2. send the message
        MessagePayload memory payload = MessagePayload(
            28110, // spec version of target chain <----------- This may be changed, go to https://pangoro.subscan.io/runtime get the latest spec version
            2654000000, // call weight
            callEncoded // call encoded bytes
        );
        bytes4 lane = 0;
        sendMessage(toPangoro, lane, payload);

        nextEvmTxNonce++;
    }

    ///////////////////////////////////////////
    // used on the target chain
    ///////////////////////////////////////////
    uint256 public number;

    function add(uint256 _value) public {
        // this 'require' makes this function only be called by the dapp contract on the source chain
        require(
            msg.sender == deriveSenderFromRemote(),
            "msg.sender must equal to the address derived from the message sender address on the source chain"
        );
        number = number + _value;
    }
}
