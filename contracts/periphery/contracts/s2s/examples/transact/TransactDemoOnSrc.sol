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

    function remoteAdd1() public payable {
        // 1. Prepare the call with its weight that will be executed on the target chain
        (bytes memory call, uint64 weight) = PangolinCalls
            .ethereum_messageTransact(
                600000, // gas limit
                0x50275d3F95E0F2FCb2cAb2Ec7A231aE188d7319d, // <----------- change to the contract address on the target chain
                hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002" // the add function bytes that will be called on the target chain, add(2)
            );

        // 2. Construct the message payload
        MessagePayload memory payload = MessagePayload(
            28110, // spec version of the target chain <----------- go to https://pangolin.subscan.io/runtime get the latest spec version
            weight, // call weight
            call // call bytes
        );

        // 3. Send the message payload to the Pangolin Chain through a lane
        _sendMessage(_PANGOLIN_CHAIN_ID, _PANGORO_PANGOLIN_LANE_ID, payload);
    }

    function remoteAdd2(
        bytes4 outboundLaneId,
        uint32 specVersionOfPangolin,
        address to
    ) public payable {
        _transactOnPangolin(
            outboundLaneId,
            specVersionOfPangolin,
            to,
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002",
            600000
        );
    }
}
