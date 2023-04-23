// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IMessageGateway.sol";

contract GoerliDapp {
    address public gatewayAddress;

    constructor(address _gatewayAddress) {
        gatewayAddress = _gatewayAddress;
    }

    function remoteAdd(address pangolinDapp, uint256 value) external payable {
        bytes memory message = abi.encode(value);
        IMessageGateway(gatewayAddress).send(pangolinDapp, message);
    }
}
