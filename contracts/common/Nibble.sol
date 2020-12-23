// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

library Nibble {
    // keyToNibbles turns bytes into nibbles, assumes they are already ordered in LE
    function keyToNibbles(bytes memory src)
        internal
        pure
        returns (bytes memory des)
    {
        if (src.length == 0) {
            return des;
        } else if (src.length == 1 && uint8(src[0]) == 0) {
            return hex"0000";
        }
        uint256 l = src.length * 2;
        des = new bytes(l);
        for (uint256 i = 0; i < src.length; i++) {
            des[2 * i] = bytes1(uint8(src[i]) / 16);
            des[2 * i + 1] = bytes1(uint8(src[i]) % 16);
        }
    }

    // nibblesToKeyLE turns a slice of nibbles w/ length k into a little endian byte array, assumes nibbles are already LE
    function nibblesToKeyLE(bytes memory src)
        internal
        pure
        returns (bytes memory des)
    {
        uint256 l = src.length;
        if (l % 2 == 0) {
            des = new bytes(l / 2);
            for (uint256 i = 0; i < l; i += 2) {
                uint8 a = uint8(src[i]);
                uint8 b = uint8(src[i + 1]);
                des[i / 2] = bytes1(((a << 4) & 0xF0) | (b & 0x0F));
            }
        } else {
            des = new bytes(l / 2 + 1);
            des[0] = src[0];
            for (uint256 i = 2; i < l; i += 2) {
                uint8 a = uint8(src[i - 1]);
                uint8 b = uint8(src[i]);
                des[i / 2] = bytes1(((a << 4) & 0xF0) | (b & 0x0F));
            }
        }
    }
}
