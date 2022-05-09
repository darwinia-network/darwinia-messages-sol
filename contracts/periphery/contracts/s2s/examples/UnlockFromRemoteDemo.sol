// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../PangoroSmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";

contract UnlockFromRemoteDemo is PangoroSmartChainXApp {
    
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
        sendMessageToPangolin(
            200000000000000000000, // deliveryAndDispatchFee
            2654000000, // call weight
            callEncoded // call encoded bytes
        );
    }

}
