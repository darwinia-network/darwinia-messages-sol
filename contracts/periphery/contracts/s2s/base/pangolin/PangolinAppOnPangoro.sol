// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../SmartChainAppOnTarget.sol";

pragma experimental ABIEncoderV2;

abstract contract PangolinAppOnPangoro is SmartChainAppOnTarget {
    function init() internal {
        srcChainId = 0x7061676c; // pagl
        tgtStorageKeyForLastDeliveredNonce = 0xd86d7f611f4d004e041fda08f633f101e5f83cf83f2127eb47afdc35d6e43fab;
    }
}