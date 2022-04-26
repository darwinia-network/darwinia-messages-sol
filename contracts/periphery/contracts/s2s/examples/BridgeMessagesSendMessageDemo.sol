// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "../SmartChainApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

contract BridgeMessagesSendMessageDemo is SmartChainApp {
    function doSendMessage() public payable {

        //////////////////////////////
        // 1. prepare the message
        //////////////////////////////
        S2SBacking.UnlockFromRemoteCall memory unlockFromRemotecall = S2SBacking.UnlockFromRemoteCall(
            hex"1402",
            0x6D6F646C64612f6272696e670000000000000000,
            100000,
            hex"d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d"
        );
        bytes memory callEncoded = S2SBacking.encodeUnlockFromRemoteCall(unlockFromRemotecall);
        Types.Message memory message = buildMessage(28080, 2654000000, callEncoded);

        //////////////////////////////
        // 2. send the message
        //////////////////////////////
        sendMessage(bytes2(0x2b03), 0, 200000000000000000000, message);


    }
}