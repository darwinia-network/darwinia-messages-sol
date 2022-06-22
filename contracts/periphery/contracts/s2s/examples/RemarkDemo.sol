// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../xapps/CrabXApp.sol";
import "../types/PalletSystem.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

pragma experimental ABIEncoderV2;

// CrabSmartChain remote call remark of Darwinia
contract RemarkDemo is CrabXApp, Ownable {
    event OutputNonce(uint256 nonce);

    constructor() public {
        init();
    }

    function remark() public payable {
        // 1. prepare the call that will be executed on the target chain
        PalletSystem.RemarkCall memory call = PalletSystem.RemarkCall(
            hex"0009", // the call index of remark_with_event
            hex"12345678"
        );
        bytes memory callEncoded = PalletSystem.encodeRemarkCall(call);

        // 2. send the message
        MessagePayload memory payload = MessagePayload(
            1210, // spec version of target chain <----------- This may be changed, go to https://darwinia.subscan.io/runtime get the latest spec version
            2654000000, // call weight
            callEncoded // call encoded bytes
        );
        bytes4 lane = 0;
        uint64 nonce = sendMessage(toDarwinia, lane, payload);
        emit OutputNonce(nonce);
    }

    // If you want to update the configs, you can add the following function
    function setStorageAddress(address _storageAddress) public onlyOwner {
        storageAddress = _storageAddress;
    }

    function setDispatchAddress(address _dispatchAddress) public onlyOwner {
        dispatchAddress = _dispatchAddress;
    }

    function setRemoteSender(address _remoteSender)
        public
        onlyOwner
    {
        remoteSender = _remoteSender;
    }

    function setToDarwinia(BridgeConfig memory config) public onlyOwner {
        toDarwinia = config;
    }

    function setToCrabParachain(BridgeConfig memory config) public onlyOwner {
        toCrabParachain = config;
    }
}
