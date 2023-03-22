// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PangolinEndpoint.sol";

// This example Dapp includes:
//   1. Caller: local business contract
//   2. PangolinEndpoint: local endpoint contract
//   3. PangoroEndpoint: remote endpoint contract
//   4. Callee: remote business contract
// Call Pangoro.callee.add(2) on Pangolin
contract Caller {
    address public endpointAddress;

    constructor(address _endpointAddress) {
        endpointAddress = _endpointAddress;
    }

    function remoteAdd(
        address calleeAddress
    ) external payable returns (uint256) {
        uint256 messageId = PangolinEndpoint(endpointAddress).remoteExecute{
            value: msg.value
        }(
            6006, // latest spec version of pangoro
            calleeAddress,
            hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002", // add(2)
            120000 // gas limit
        );

        return messageId;
    }
}
