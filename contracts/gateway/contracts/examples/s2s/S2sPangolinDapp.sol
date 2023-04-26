// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../interfaces/IMessageGateway.sol";

contract S2sPangolinDapp {
    address public gatewayAddress;

    constructor(address _gatewayAddress) {
        gatewayAddress = _gatewayAddress;
    }

    function remoteAdd(address pangoroDapp) external payable {
        bytes memory message = abi.encode(uint256(2));
        IMessageGateway(gatewayAddress).send{value: msg.value}(
            pangoroDapp,
            message
        );
    }
}
