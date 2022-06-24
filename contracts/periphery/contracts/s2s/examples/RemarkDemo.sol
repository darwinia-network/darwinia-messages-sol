// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../xapps/CrabXApp.sol";
import "../calls/DarwiniaCalls.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

pragma experimental ABIEncoderV2;

// CrabSmartChain remote call remark of Darwinia
contract RemarkDemo is CrabXApp, Ownable {
    event OutputNonce(uint256 nonce);

    constructor() public {
        init();
    }

    function remoteRemark() public payable {
        // 1. Prepare the call with its weight that will be executed on the target chain
        (bytes memory call, uint64 weight) = DarwiniaCalls
            .system_remarkWithEvent(hex"12345678");

        // 2. Construct the message payload
        MessagePayload memory payload = MessagePayload(
            1210, // spec version of target chain <----------- go to https://darwinia.subscan.io/runtime get the latest spec version
            weight, // call weight
            call // call encoded bytes
        );

        // 3. Send the message payload to the Darwinia Chain through a lane
        bytes4 laneId = 0;
        uint64 messageNonce = sendMessage(toDarwinia, laneId, payload);
        emit OutputNonce(messageNonce);
    }

    // If you want to update the configs, you can add the following function
    function setStorageAddress(address _storageAddress) public onlyOwner {
        storageAddress = _storageAddress;
    }

    function setDispatchAddress(address _dispatchAddress) public onlyOwner {
        dispatchAddress = _dispatchAddress;
    }

    function setMessageSenderOnSrcChain(address _messageSenderOnSrcChain)
        public
        onlyOwner
    {
        messageSenderOnSrcChain = _messageSenderOnSrcChain;
    }

    function setToDarwinia(BridgeConfig memory config) public onlyOwner {
        toDarwinia = config;
    }

    function setToCrabParachain(BridgeConfig memory config) public onlyOwner {
        toCrabParachain = config;
    }
}
