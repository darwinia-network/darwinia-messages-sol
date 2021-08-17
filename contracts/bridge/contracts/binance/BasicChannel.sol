// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./CrossChainFilter.sol";

contract BasicChannel is CrossChainFilter {
    event SetChannel(address indexed inbound, address indexed outbound);

    address public inbound;
    address public outbound;

    modifier onlyInbound() {
        require(inbound == msg.sender, "only inbound");
        _;
    }

    constructor(address _inbound, address _outbound) public {
        inbound = _inbound;
        outbound = _outbound;
        emit SetChannel(inbound, outbound);
    }

    function setChannel(address _inbound, address _outbound) public sudo {
        inbound = _inbound;
        outbound = _outbound;
        emit SetChannel(inbound, outbound);
    }
}
