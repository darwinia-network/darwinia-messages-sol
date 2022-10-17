// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./PangolinEndpoint.sol";
import "../../SmartChainXLib.sol";

// pangolin > pangolin-parachain > moonbase
contract RemoteExecute_FromPangolinToMoonbase {
    address public endpoint;

    constructor(address _endpoint) {
        endpoint = _endpoint;
    }

    event Hello(address);

    function remoteAdd(address callee) external payable returns (uint256) {
        uint256 messageId = PangolinEndpoint(endpoint).targetExecute{value: msg.value}(
            5330, // pangolin-parachain spec version
            callee,
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002", // add(2),
            120000 // gas limit
        );
        
        return messageId;
    }

    function latestNonce() public view returns (uint64) {
        return SmartChainXLib.latestNonce(
            address(1024),
            0xdcdffe6202217f0ecb0ec75d8a09b32c96c246acb9b55077390e3ca723a0ca1f,
            0x70616c69
        );
    }
}
