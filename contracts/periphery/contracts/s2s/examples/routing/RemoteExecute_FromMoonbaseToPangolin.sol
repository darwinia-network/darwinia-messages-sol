// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./MoonbaseEndpoint.sol";

// moonbase > pangolin-parachain > pangolin
contract RemoteExecute_FromMoonbaseToPangolin {
    address public endpoint;

    constructor(address _endpoint) {
        endpoint = _endpoint;
    }

    function remoteAdd(address callee, uint128 deliveryAndDispatchFee)
        external
    {
        MoonbaseEndpoint(endpoint).remoteExecute(
            29030, // pangolin spec version
            callee,
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002", // add(2),
            120000, // gas limit
            deliveryAndDispatchFee
        );
    }
}
