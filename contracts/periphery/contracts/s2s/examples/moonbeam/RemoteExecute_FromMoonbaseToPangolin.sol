// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./MoonbaseEndpoint.sol";

// moonbase > pangolin-parachain > pangolin
contract RemoteExecute_FromMoonbaseToPangolin {
    address public endpoint;

    constructor(address _endpoint) {
        endpoint = _endpoint;
    }

    function remoteAdd(address callee) external payable {
        MoonbaseEndpoint(endpoint).remoteExecute{value: msg.value}(
            29030, // pangolin spec version
            callee,
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002", // add(2),
            600000, // gas limit
            200_000_000_000 * 10**9 // deliveryAndDispatchFee
        );
    }
}
