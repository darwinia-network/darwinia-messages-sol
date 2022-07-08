// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/IERC20.sol";
import "../../baseapps/pangolin/PangolinAppOnPangoro.sol";

contract Issuing is PangolinAppOnPangoro {
    constructor() {
        _init();
    }

    event TokenIssued(address mappedToken, address recipient, uint256 amount);

    function issueFromRemote(
        address mappedToken,
        address recipient,
        uint256 amount
    ) external {
        // Check that the sender is authorized
        require(
            _isDerivedFromRemote(msg.sender), 
            "msg.sender is not derived from remote"
        );

        // Issue
        (bool success,) = mappedToken.call(
            abi.encodeWithSelector(IERC20.mint.selector, recipient, amount)
        );
        if (!success) {
            revert("Issue failed");
        }

        // Emit an event
        emit TokenIssued(mappedToken, recipient, amount);
    }

    function setSrcMessageSender(address _srcMessageSender) public {
        srcMessageSender = _srcMessageSender;
    }
}
