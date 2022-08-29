// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../PangolinToPangolinParachainEndpoint.sol";
import "../../types/PalletMessageRouter.sol";
import "../../types/PalletEthereumXcm.sol";

// pangolin > pangolin-parachain > moonbase
contract RemoteExecuteOnMoonbeam {
    address public endpoint;

    constructor(address _endpoint) {
        endpoint = _endpoint;
    }

    function remoteExecuteOnMoonbeam(
        address callReceiver,
        bytes calldata callPayload,
        uint256 gasLimit
    ) external returns (uint256) {
        uint256 messageId = PangolinToPangolinParachainEndpoint(endpoint)
            .remoteExecuteOnMoonbeam(
                28140, // pangolin-parachain spec version
                callReceiver,
                callPayload,
                gasLimit
            );

        return messageId;
    }
}
