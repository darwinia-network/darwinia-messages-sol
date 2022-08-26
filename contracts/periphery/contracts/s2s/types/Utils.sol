// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "hardhat/console.sol";

library Utils {
    function encodeEnumItem(uint8 _enumItemIndex, bytes memory _enumItemData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_enumItemIndex, _enumItemData);
    }
}
