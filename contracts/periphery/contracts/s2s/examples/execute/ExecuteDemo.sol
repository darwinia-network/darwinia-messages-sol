// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ToPangolinEndpoint.sol";

// Call Pangolin.callee.add(2) on Pangoro
contract ExecuteDemo {
    address public endpoint;

    constructor(address _endpoint) {
        endpoint = _endpoint;
    }

    function remoteAdd(address callee) external payable returns (uint256) {
        uint256 messageId = ToPangolinEndpoint(endpoint).remoteExecute(
            28140, // latest spec version of pangolin
            callee,
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002", // add(2)
            120000 // gas limit
        );

        return messageId;
    }
}