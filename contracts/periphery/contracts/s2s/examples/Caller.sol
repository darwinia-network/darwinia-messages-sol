// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ToPangoroEndpoint.sol";

// Call Pangoro.callee.add(2) on Pangolin
contract Caller {
    address public endpointAddress;

    constructor(address _endpointAddress) {
        endpointAddress = _endpointAddress;
    }

    function remoteAdd(
        address calleeAddress
    ) external payable returns (uint256) {
        uint256 messageId = ToPangoroEndpoint(endpointAddress).remoteExecute(
            6006, // latest spec version of pangoro
            calleeAddress,
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002", // add(2)
            120000 // gas limit
        );

        return messageId;
    }
}
