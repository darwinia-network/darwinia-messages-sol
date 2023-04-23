// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IMessageGateway.sol";

contract GoerliDapp {
    address public gatewayAddress;

    constructor(address _gatewayAddress) {
        gatewayAddress = _gatewayAddress;
    }

    function remoteAdd(address pangolinDapp) external payable {
        bytes memory message = abi.encode(uint256(2));
        IMessageGateway(gatewayAddress).send{value: msg.value}(
            pangolinDapp,
            message
        );
    }
}
