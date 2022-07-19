// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../ToPangolinEndpoint.sol";

// Call Pangolin.add(2) from Pangoro
contract TransactDemo {
    address public endpoint;

    constructor(address _endpoint) {
        endpoint = _endpoint;
    }

    function remoteAdd() external returns (uint256) {
        uint256 messageId = ToPangolinEndpoint(endpoint).remoteTransact(
            28160, // latest spec version of pangolin
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002", // add(2)
            120000 // gas limit
        );

        return messageId;
    }
}
