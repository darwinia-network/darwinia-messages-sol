// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../xapps/PangolinXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "../../interfaces/IERC20.sol";
import "../../types/PalletEthereum.sol";

pragma experimental ABIEncoderV2;

contract Issuing is PangolinXApp {
    constructor() public {
        init();
    }

    function issueFromRemote(
        address token,
        address recipient,
        uint256 amount
    ) external {
        // ensure this function only be called by the dapp contract on the source chain
        require(
            msg.sender == deriveSenderFromRemote(),
            "msg.sender must equal to the address derived from the message sender address on the source chain"
        );

        // get mapping token address from factory

        // ensure the token has beed registered

        // issue erc20 tokens

        // emit event
    }
}
