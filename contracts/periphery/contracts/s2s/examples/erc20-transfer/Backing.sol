// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../baseapps/pangolin/PangolinApp.sol";
import "../../calls/PangolinCalls.sol";

pragma experimental ABIEncoderV2;

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

    struct LockedInfo {
        address token;
        address sender;
        uint256 amount;
    }

    // (messageId => lockedInfo)
    mapping(bytes => LockedInfo) public lockMessages;

    event TokenLocked(
        bytes4 laneId,
        uint64 nonce,
        address token,
        address recipient,
        uint256 amount
    );

    function lockAndRemoteIssue(
        uint32 specVersion,
        bytes4 laneId,
        
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
        uint64 messageNonce = _transactOnPangoro(
            ROLI_LANE_ID, 
            specVersion, 
            issuingContractAddress, 
            abi.encodeWithSelector(
                IIssuing.issueFromRemote.selector,
                mappedToken,
                recipient,
                amount
            ), 
            600000
        );

        // Record the lock info
        bytes memory messageId = abi.encode(laneId, messageNonce);
        lockMessages[messageId] = LockedInfo(token, msg.sender, amount);

        // Emit an event
        emit TokenLocked(laneId, messageNonce, token, recipient, amount);
    }
}
