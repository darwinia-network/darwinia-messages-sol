// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

pragma experimental ABIEncoderV2;

// Remote call from Pangolin SmartChain 
abstract contract PangolinXApp is SmartChainXApp {
    function init() internal {
        srcChainId = 0;
    }

    BridgeConfig internal toPangoro =
        BridgeConfig(
            0x2b03,
            0x7621b367d09b75f6876b13089ee0ded52edb70953213f33a6ef6b8a5e3ffcab2,
            0xc9b76e645ba80b6ca47619d64cb5e58d96c246acb9b55077390e3ca723a0ca1f,
            0xd86d7f611f4d004e041fda08f633f101e5f83cf83f2127eb47afdc35d6e43fab
        );
    
    BridgeConfig internal toPangolinParachain =
        BridgeConfig(
            0x3f03,
            0x39bf2363dd0720bd6e11a4c86f4949322edb70953213f33a6ef6b8a5e3ffcab2,
            0xdcdffe6202217f0ecb0ec75d8a09b32c96c246acb9b55077390e3ca723a0ca1f,
            0xd86d7f611f4d004e041fda08f633f101e5f83cf83f2127eb47afdc35d6e43fab
        );
}
