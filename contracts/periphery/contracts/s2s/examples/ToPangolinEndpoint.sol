// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../MessageEndpoint.sol";

// Pangoro to Pangolin
contract ToPangolinEndpoint is MessageEndpoint {
    constructor() {
        outboundLaneId = 0x726f6c69;
        inboundLaneId = 0x726f6c69;
        storageAddress = address(1024);
        dispatchAddress = address(1025);
        storageKeyForMarketFee = 0x30d35416864cf657db51d3bc8505602f2edb70953213f33a6ef6b8a5e3ffcab2;
        storageKeyForLatestNonce = 0xd86d7f611f4d004e041fda08f633f10196c246acb9b55077390e3ca723a0ca1f;
        storageKeyForLastDeliveredNonce = 0xd86d7f611f4d004e041fda08f633f101e5f83cf83f2127eb47afdc35d6e43fab;
        sendMessageCallIndex = 0x1103;
        remoteMessageTransactCallIndex = 0x2901;
        remoteSmartChainId = 43;
    }

    function _canBeExecuted(address, bytes calldata)
        internal
        pure
        override
        returns (bool)
    {
        return true;
    }

    function remoteDispatch(
        uint32 pangolinSpecVersion,
        bytes memory pangolinCallEncoded,
        uint64 pangolinCallWeight
    ) external payable returns (uint256) {
        return
            _remoteDispatch(
                pangolinSpecVersion,
                pangolinCallEncoded,
                pangolinCallWeight
            );
    }
}
