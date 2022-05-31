// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXLib.sol";
import "../types/PalletEthereum.sol";

// used for testing
contract SubstrateTransact {
    function substrateTransact() public payable {
        // 1. prepare the call that will be executed on the target chain
        PalletEthereum.SubstrateTransactCall memory call = PalletEthereum.SubstrateTransactCall(
            0x2902,
            0xC2Bf5F29a4384b1aB0C063e1c666f02121B6084a,
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002"
        );
        bytes memory callEncoded = PalletEthereum.encodeSubstrateTransactCall(call);

        // 2. send the message
        SmartChainXLib.dispatch(
            0x0000000000000000000000000000000000000019, 
            callEncoded,
            "Dispatch substrate_transact failed"
        );
    }
}
