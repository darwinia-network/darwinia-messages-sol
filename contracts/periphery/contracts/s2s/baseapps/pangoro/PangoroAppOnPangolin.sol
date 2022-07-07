// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../BaseAppOnTarget.sol";

pragma experimental ABIEncoderV2;

abstract contract PangoroAppOnPangolin is BaseAppOnTarget {
    function _init() internal {
        srcChainId = _PANGORO_CHAIN_ID;
        tgtStorageKeyForLastDeliveredNonce = 0xc9b76e645ba80b6ca47619d64cb5e58de5f83cf83f2127eb47afdc35d6e43fab;
    }
}
