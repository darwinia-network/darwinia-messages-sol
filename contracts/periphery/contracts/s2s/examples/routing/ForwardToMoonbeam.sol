// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../PangolinToPangolinParachainEndpoint.sol";
import "../../types/PalletMessageRouter.sol";
import "../../types/PalletEthereumXcm.sol";

// pangolin > pangolin-parachain > moonbase
contract ForwardToMoonbeam {
    address public endpoint;

    constructor(address _endpoint) {
        endpoint = _endpoint;
    }

    function remoteForwardToMoonbeam(address to, bytes memory input)
        external
        returns (uint256)
    {
        bytes memory call = PalletMessageRouter.buildForwardToMoonbeamCall(
            hex"1a01",
            PalletEthereumXcm.buildTransactCall(
                hex"2600",
                6000000,
                to,
                0,
                input
            )
        );

        // 2. Dispatch the call
        uint256 messageId = PangolinToPangolinParachainEndpoint(endpoint).remoteDispatch(
            28140, // latest spec version of pangolin
            call,
            0 // weight
        );

        return messageId;
    }
}
