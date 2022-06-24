// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

pragma experimental ABIEncoderV2;

// Remote call from Pangoro SmartChain 
abstract contract PangoroXApp is SmartChainXApp {
    function init() internal {
        srcChainId = 0;
    }

    BridgeConfig internal toPangolin =
        BridgeConfig(
            0x1103,
            0x30d35416864cf657db51d3bc8505602f2edb70953213f33a6ef6b8a5e3ffcab2,
            0xd86d7f611f4d004e041fda08f633f10196c246acb9b55077390e3ca723a0ca1f,
            0xc9b76e645ba80b6ca47619d64cb5e58de5f83cf83f2127eb47afdc35d6e43fab
        );
}
