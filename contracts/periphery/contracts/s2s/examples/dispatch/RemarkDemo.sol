// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ToPangolinEndpoint.sol";
import "../../types/PalletSystem.sol";

// Call Pangolin.remark_with_event on Pangoro
contract RemarkDemo {
    address public endpoint;

    constructor(address _endpoint) {
        endpoint = _endpoint;
    }

    function remoteRemark(bytes memory _remark) external returns (uint256) {
        // 1. Prepare the call and its weight which will be executed on the target chain
        PalletSystem.RemarkCall memory call = PalletSystem.RemarkCall(
            hex"0009",
            _remark
        );
        bytes memory encodedCall = PalletSystem.encodeRemarkCall(call);
        uint64 weight = uint64(_remark.length * 2_000);

        // 2. Dispatch the call
        uint256 messageId = ToPangolinEndpoint(endpoint).remoteDispatch(
            28140, // latest spec version of pangolin
            encodedCall,
            weight
        );

        return messageId;
    }
}
