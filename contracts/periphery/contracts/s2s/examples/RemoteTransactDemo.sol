// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "../types/PalletEthereum.sol";

// deploy on the target chain first, then deploy on the source chain
contract RemoteTransactDemo is SmartChainXApp, Ownable {
    uint256 public number;

    // source chain ethereum sender address,
    // it will be updated after the app is deployed on the source chain.
    address public sourceChainEthereumAddress;

    constructor() public {
        // Globle settings
        dispatchAddress = 0x0000000000000000000000000000000000000019;
        callIndexOfSendMessage = 0x2b03;
        storageAddress = 0x000000000000000000000000000000000000001a;
        callbackSender = 0x6461722f64766D70000000000000000000000000;

        // Bridge settings
        bridgeConfigs[0] = BridgeConfig(
            // storage key for Darwinia market fee
            0x190d00dd4103825c78f55e5b5dbf8bfe2edb70953213f33a6ef6b8a5e3ffcab2,
            // storage key for the latest nonce of Darwinia message lane
            hex"c9b76e645ba80b6ca47619d64cb5e58d96c246acb9b55077390e3ca723a0ca1f11d2df4e979aa105cf552e9544ebd2b500000000",
            // lane id, lane to Darwinia
            0,
            // source chain id
            0x00000000
        );
    }

    ///////////////////////////////////////////
    // used on the source chain
    ///////////////////////////////////////////

    function callAddOnTheTargetChain() public payable {
        // 1. prepare the call that will be executed on the target chain
        PalletEthereum.SubstrateTransactCall memory call = PalletEthereum
            .SubstrateTransactCall(
                // the call index of substrate_transact
                0x2902,
                // the address of the contract on the target chain
                0x50275d3F95E0F2FCb2cAb2Ec7A231aE188d7319d, // <------------------ change to the contract address on the target chain
                // the add function bytes that will be called on the target chain, add(2)
                hex"1003e2d20000000000000000000000000000000000000000000000000000000000000002"
            );
        bytes memory callEncoded = PalletEthereum.encodeSubstrateTransactCall(
            call
        );

        // 2. send the message
        MessagePayload memory payload = MessagePayload(
            28110, // spec version of target chain <----------- This may be changed, go to https://pangoro.subscan.io/runtime get the latest spec version
            2654000000, // call weight
            callEncoded // call encoded bytes
        );
        uint64 nonce = sendMessage(
            0, // bridge id, which is the mapping key of bridgeConfigs
            payload // message payload
        );
    }

    function onMessageDelivered(
        bytes4 lane,
        uint64 nonce,
        bool result
    ) external override {
        require(
            msg.sender == callbackSender,
            "Only pallet address is allowed call 'onMessageDelivered'"
        );
        // TODO: Your code goes here...
    }

    ///////////////////////////////////////////
    // used on the target chain
    ///////////////////////////////////////////

    function setSourceChainEthereumAddress(
        uint16 bridgeId,
        address _sourceChainEthereumAddress
    ) public onlyOwner {
        sourceChainEthereumAddress = _sourceChainEthereumAddress;
    }

    function add(uint256 _value) public {
        requireSourceChainEthereumAddress(0, sourceChainEthereumAddress);
        number = number + _value;
    }
}
