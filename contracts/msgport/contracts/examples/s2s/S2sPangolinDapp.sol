// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../interfaces/IMsgport.sol";

contract S2sPangolinDapp {
    address public gatewayAddress;

    constructor(address _gatewayAddress) {
        gatewayAddress = _gatewayAddress;
    }

    function remoteAdd(address pangoroDapp) external payable {
        bytes memory message = abi.encode(uint256(2));
        IMsgport(gatewayAddress).send{value: msg.value}(
            pangoroDapp,
            message,
            50_000,
            2457757432886
        );
    }
}
