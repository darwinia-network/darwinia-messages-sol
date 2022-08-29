// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library Utils {
    function encodeEnumItem(uint8 _enumItemIndex, bytes memory _enumItemData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_enumItemIndex, _enumItemData);
    }

    // function encodeVec(uint16 length, bytes)
}
