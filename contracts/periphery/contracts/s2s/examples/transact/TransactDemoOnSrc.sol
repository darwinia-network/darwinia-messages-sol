// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../baseapps/pangoro/PangoroApp.sol";
import "../../calls/PangolinCalls.sol";

// deploy on the target chain first, then deploy on the source chain
contract TransactDemo is PangoroApp {
    constructor() public {
        _init();
    }

    function remoteAdd_way1(
        uint32 specVersionOfPangolin, // https://pangolin.subscan.io/runtime
        address receivingContract
    ) public payable {
        // 1. Prepare the call with its weight that will be executed on the target chain
        (bytes memory call, uint64 weight) = PangolinCalls
            .ethereum_messageTransact(
                600000, // gas limit
                receivingContract,
                hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002" // add(2)
            );

        // 2. Construct the message payload
        MessagePayload memory payload = MessagePayload(
            specVersionOfPangolin,
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

    function remoteAdd_way2(
        uint32 specVersionOfPangolin,
        address receivingContract
    ) public payable {
        uint64 messageNonce = _remoteTransact(
            _PANGOLIN_CHAIN_ID,
            _PANGORO_PANGOLIN_LANE_ID,
            specVersionOfPangolin,
            receivingContract,
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002", // add(2)
            600000 // gas limit
        );
    }
}
