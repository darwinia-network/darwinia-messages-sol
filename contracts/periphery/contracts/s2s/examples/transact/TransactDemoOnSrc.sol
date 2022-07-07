// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../baseapps/pangoro/PangoroApp.sol";
import "../../calls/PangolinCalls.sol";

pragma experimental ABIEncoderV2;

// deploy on the target chain first, then deploy on the source chain
contract TransactDemo is PangoroApp {
    constructor() public {
        _init();
    }

    function remoteAdd_way1(address receivingContract) public payable {
        // 1. Prepare the call with its weight that will be executed on the target chain
        (bytes memory call, uint64 weight) = PangolinCalls
            .ethereum_messageTransact(
                600000, // gas limit
                receivingContract,
                hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002" // the add function bytes that will be called on the target chain, add(2)
            );

        // 2. Construct the message payload
        MessagePayload memory payload = MessagePayload(
            28110, // spec version of Pangolin <----------- go to https://pangolin.subscan.io/runtime get the latest spec version
            weight,
            call
        );

        // 3. Send the message payload to the Pangolin Chain through a lane
        uint64 messageNonce = _sendMessage(
            _PANGOLIN_CHAIN_ID,
            _PANGORO_PANGOLIN_LANE_ID,
            payload
        );
    }

    function remoteAdd_way2(address receivingContract) public payable {
        uint64 messageNonce = _remoteTransact(
            _PANGOLIN_CHAIN_ID,
            _PANGORO_PANGOLIN_LANE_ID,
            28110, // spec version of Pangolin
            receivingContract,
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002",
            600000 // gas limit
        );
    }
}
