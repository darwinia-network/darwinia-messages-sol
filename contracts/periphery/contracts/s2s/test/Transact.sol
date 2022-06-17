// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXLib.sol";
import "../types/PalletEthereum.sol";

// used for testing
contract Transact {
    function transact() public payable {
        // 1. prepare the call that will be executed on the target chain
        PalletEthereum.TransactCall memory call = PalletEthereum
            .TransactCall(
                // the call index of substrate_transact
                0x2902,
                // the evm transaction to transact
                PalletEthereum.buildTransactionV2(
                    0, // evm tx nonce, nonce on the target chain + pending nonce on the source chain + 1
                    1000000000, // gasPrice, get from the target chain
                    600000, // gasLimit, get from the target chain
                    0x50275d3F95E0F2FCb2cAb2Ec7A231aE188d7319d, // <------------------ change to the contract address on the target chain
                    0, // value, 0 means no value transfer
                    hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002" // the add function bytes that will be called on the target chain, add(2)
                )
            );
        bytes memory callEncoded = PalletEthereum.encodeTransactCall(call);

        // 2. send the message
        SmartChainXLib.dispatch(
            0x0000000000000000000000000000000000000019, 
            callEncoded,
            "Dispatch substrate_transact failed"
        );
    }
}
