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

    function setMessageSenderOnSrcChain(address _messageSenderOnSrcChain) public {
        messageSenderOnSrcChain = _messageSenderOnSrcChain;
    }

    function issueFromRemote(
        address mappedToken,
        address recipient,
        uint256 amount
    ) external {
        // ensure this function only be called by the dapp contract on the source chain
        require(
            msg.sender == deriveSenderFromRemote(),
            "msg.sender must equal to the address derived from the message sender address on the source chain"
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
