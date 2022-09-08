// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./PangolinEndpoint.sol";

// pangolin > pangolin-parachain > moonbase
contract RemoteExecute_FromPangolinToMoonbeam {
    address public endpoint;

    constructor(address _endpoint) {
        endpoint = _endpoint;
    }

    function remoteAdd(address callee) external returns (uint256) {
        uint256 messageId = PangolinEndpoint(endpoint).remoteExecute(
            5320, // pangolin-parachain spec version
            callee,
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002", // add(2),
            120000 // gas limit
        );

        return messageId;
    }
}
