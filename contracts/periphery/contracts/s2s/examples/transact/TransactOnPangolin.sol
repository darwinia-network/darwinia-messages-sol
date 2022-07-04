// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../base/pangoro/PangoroAppOnPangolin.sol";
import "../../calls/PangolinCalls.sol";

pragma experimental ABIEncoderV2;

// deploy on the target chain first, then deploy on the source chain
contract TransactDemoOnPangolin is PangoroAppOnPangolin {
    uint256 public number;

    constructor() public {
        init();
    }

    function add(uint256 _value) public {
        // This function is only allowed to be called by the derived address
        // of the message sender on the source chain.
        require(
            derivedFromRemote(msg.sender),
            "msg.sender is not derived from remote"
        );
        number = number + _value;
    }

    function getLastDeliveredNonce(bytes4 inboundLaneId)
        public
        view
        returns (uint64)
    {
        return lastDeliveredNonceOf(inboundLaneId);
    }
}