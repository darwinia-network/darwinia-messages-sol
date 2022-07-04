// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../xapps/PangoroXApp.sol";
import "../calls/PangolinCalls.sol";

pragma experimental ABIEncoderV2;

// deploy on the target chain first, then deploy on the source chain
contract TransactDemo is PangoroXApp {
    constructor() public {
        init();
    }

    ///////////////////////////////////////////
    // used on the source chain
    ///////////////////////////////////////////
    function remoteAdd() public payable {
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
        bytes4 outboundLaneId = 0x726f6c69;
        sendMessage(toPangolin, outboundLaneId, payload);
    }

    ///////////////////////////////////////////
    // used on the target chain
    ///////////////////////////////////////////
    uint256 public number;

    function add(uint256 _value) public {
        // This function is only allowed to be called by the derived address
        // of the message sender on the source chain.
        require(
            derivedFromRemote(msg.sender),
            "msg.sender is not derived from remote"
        );
        number = number + _value;
    }

    function getLastDeliveredNonce(bytes4 inboundLaneId)
        public
        view
        returns (uint64)
    {
        return lastDeliveredNonceOf(inboundLaneId);
    }
}
