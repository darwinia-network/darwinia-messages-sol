// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

pragma experimental ABIEncoderV2;

// Remote call from Pangoro SmartChain 
abstract contract PangoroApp is SmartChainApp {
    function init() internal {
        bridgeConfigs[PANGOLIN_CHAIN_ID] = BridgeConfig(
            0x1103,
            0x30d35416864cf657db51d3bc8505602f2edb70953213f33a6ef6b8a5e3ffcab2,
            0xd86d7f611f4d004e041fda08f633f10196c246acb9b55077390e3ca723a0ca1f
        );
    }
}
