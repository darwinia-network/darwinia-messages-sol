// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library TypeUtils {
    function encodeEnumItem(uint8 _enumItemIndex, bytes memory _enumItemData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_enumItemIndex, _enumItemData);
    }
}
