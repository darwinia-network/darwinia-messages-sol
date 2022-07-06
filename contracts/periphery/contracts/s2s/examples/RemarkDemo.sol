// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../baseapps/crab/CrabApp.sol";
import "../calls/DarwiniaCalls.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

pragma experimental ABIEncoderV2;

// CrabSmartChain remote call remark of Darwinia
contract RemarkDemo is CrabApp, Ownable {
    constructor() public {
        _init();
    }

    event OutputNonce(uint256 nonce);

    function remoteRemark() public payable {
        // 1. Prepare the call with its weight that will be executed on the target chain
        (bytes memory call, uint64 weight) = DarwiniaCalls
            .system_remarkWithEvent(hex"12345678");

        // 2. Construct the message payload
        MessagePayload memory payload = MessagePayload(
            1210, // spec version of the target chain <----------- go to https://darwinia.subscan.io/runtime get the latest spec version
            weight, // call weight
            call // call bytes
        );

        // 3. Send the message payload to the Darwinia Chain through a lane
        uint64 messageNonce = _sendMessage(
            DARWINIA_CHAIN_ID,
            ZERO_LANE_ID,
            payload
        );
        emit OutputNonce(messageNonce);
    }

    // If you want to update the configs, you can add the following function
    function setSrcStoragePrecompileAddress(
        address _srcStoragePrecompileAddress
    ) public onlyOwner {
        srcStoragePrecompileAddress = _srcStoragePrecompileAddress;
    }

    function setSrcDispatchPrecompileAddress(
        address _srcDispatchPrecompileAddress
    ) public onlyOwner {
        srcDispatchPrecompileAddress = _srcDispatchPrecompileAddress;
    }
}
