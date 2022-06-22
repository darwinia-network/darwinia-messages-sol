// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/IERC20.sol";
import "../../xapps/PangolinXApp.sol";
import "../../SmartChainXLib.sol";
import "../../types/PalletEthereum.sol";

pragma experimental ABIEncoderV2;

contract Issuing is PangolinXApp {
    constructor() {
        init();
    }

    event TokenIssued(address mappedToken, address recipient, uint256 amount);

    function setRemoteSender(address _remoteSender) public {
        remoteSender = _remoteSender;
    }

    function issueFromRemote(
        address mappedToken,
        address recipient,
        uint256 amount
    ) external {
        // the sender is only allowed to be called by the derived address 
        // of dapp address on the source chain.
        require(
            derivedFromRemote(msg.sender), 
            "msg.sender is not derived from remote"
        );

        // issue erc20 tokens
        (bool success, bytes memory data) = address(mappedToken).call(
            abi.encodeWithSelector(IERC20.mint.selector, recipient, amount)
        );
        SmartChainXLib.revertIfFailed(success, data, "Issue failed");

        // emit event
        emit TokenIssued(mappedToken, recipient, amount);
    }
}
