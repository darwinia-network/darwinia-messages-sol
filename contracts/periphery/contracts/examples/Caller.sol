// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GoerliEndpoint.sol";

contract Caller {
    address public endpointAddress;

    constructor(address _endpointAddress) {
        endpointAddress = _endpointAddress;
    }

    function dispatchOnParachain(
        bytes2 paraId,
        bytes memory paraCall,
        uint64 weight
    ) external payable returns (uint64 nonce) {
        nonce = GoerliEndpoint(endpointAddress).dispatchOnParachain{
            value: msg.value
        }(paraId, paraCall, weight);
    }
}
