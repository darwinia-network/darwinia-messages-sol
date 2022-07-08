// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../baseapps/pangolin/PangolinApp.sol";

interface IIssuing {
    function issueFromRemote(
        address mappedToken,
        address recipient,
        uint256 amount
    ) external;
}

contract Backing is PangolinApp {
    constructor() {
        _init();
    }

    event TokenLocked(
        bytes4 laneId,
        uint64 nonce,
        address token,
        address recipient,
        uint256 amount
    );

    function lockAndRemoteIssue(
        uint32 specVersionOfPangoro,
        
        // Lock `amount` of `token` on the source chain
        address token,

        // Remote issue `amount` of `mappedToken` to `recipient` on the target chain
        address issuingContractAddress,
        address mappedToken,
        address recipient,
        uint256 amount
    ) external payable {
        // Lock
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Remote issuing
        uint64 messageNonce = _remoteTransact(
            _PANGORO_CHAIN_ID,
            _PANGORO_PANGOLIN_LANE_ID, 
            specVersionOfPangoro, 
            issuingContractAddress, 
            abi.encodeWithSelector(
                IIssuing.issueFromRemote.selector,
                mappedToken,
                recipient,
                amount
            ), 
            600000
        );

        // Emit an event
        emit TokenLocked(_PANGORO_PANGOLIN_LANE_ID, messageNonce, token, recipient, amount);
    }
}
