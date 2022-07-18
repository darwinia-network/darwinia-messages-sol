// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./MessageHandle.sol";

contract PangolinToPangoroMessageHandle is MessageHandle {
    constructor() {
        srcOutboundLaneId = 0x726f6c69;
        tgtMessageTransactCallIndex = 0x1a01;
        srcStorageAddress = address(1024);
        srcDispatchAddress = address(1025);
        srcSendMessageCallIndex = 0x2b03;
        srcStorageKeyForMarketFee = 0x7621b367d09b75f6876b13089ee0ded52edb70953213f33a6ef6b8a5e3ffcab2;
        srcStorageKeyForLatestNonce = 0xc9b76e645ba80b6ca47619d64cb5e58d96c246acb9b55077390e3ca723a0ca1f;
        tgtWeightPerGas = 40_000;

        tgtInboundLaneId = 0x726f6c69;
        srcChainId = 0x7061676c;
        tgtSmartChainId = 45;
        tgtStorageAddress = address(1024);
        tgtStorageKeyForLastDeliveredNonce = 0xd86d7f611f4d004e041fda08f633f101e5f83cf83f2127eb47afdc35d6e43fab;
    }
}