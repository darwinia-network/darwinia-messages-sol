// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./MessageHandle.sol";

contract PangoroToPangolinMessageHandle is MessageHandle {
    constructor() {
        laneId = 0x726f6c69;
        tgtMessageTransactCallIndex = 0x2901;
        srcStorageAddress = address(1024);
        srcDispatchAddress = address(1025);
        srcSendMessageCallIndex = 0x1103;
        srcStorageKeyForMarketFee = 0x30d35416864cf657db51d3bc8505602f2edb70953213f33a6ef6b8a5e3ffcab2;
        srcStorageKeyForLatestNonce = 0xd86d7f611f4d004e041fda08f633f10196c246acb9b55077390e3ca723a0ca1f;
        tgtWeightPerGas = 40_000;
        srcChainId = 0x70616772;
        tgtSmartChainId = 43;
        tgtStorageAddress = address(1024);
        tgtStorageKeyForLastDeliveredNonce = 0xc9b76e645ba80b6ca47619d64cb5e58de5f83cf83f2127eb47afdc35d6e43fab;
    }
}