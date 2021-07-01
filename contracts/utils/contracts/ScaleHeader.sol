// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Input.sol";
import "./Bytes.sol";

pragma experimental ABIEncoderV2;

library ScaleHeader {
    using Input for Input.Data;
    using Bytes for bytes;

    function decodeBlockNumberFromBlockHeader(
        bytes memory header
    ) internal pure returns (uint32 blockNumber) {
        Input.Data memory data = Input.from(header);
        
        // skip parentHash(Hash)
        data.shiftBytes(32);

        blockNumber = decodeU32(data);
    }

    function decodeMessagesRootFromBlockHeader(
        bytes memory header
    ) internal pure returns (bytes32 messagesRoot) {
        uint256 digestOffset = 32 + decodeCompactU8aOffset(header[32]) + 32 + 32;
        Input.Data memory data = Input.from(header);
        data.shiftBytes(digestOffset);
        uint32 len = decodeU32(data);
        for (uint256 i = 0; i < len; i++) {
            uint8 b = data.decodeU8();
            if (b == 0) /*Other*/ {
                decodeU32(data);
                data.shiftBytes(36);
                return data.decodeBytes32();
            } else if (b == 2) /*ChangesTrieRoot*/ {
                data.shiftBytes(32);
            } else if (b == 4 || b == 5 || b == 6) /*Consensus, Seal, PreRuntime*/ {
                data.shiftBytes(4);
                data.shiftBytes(decodeU32(data));
            } else if (b == 7) /*ChangesTrieSignal*/ {
                uint8 tag = data.decodeU8();
                if (tag == 0) {
                    uint8 option = data.decodeU8();
                    if (option == 0) {
                        continue; 
                    } else if (option == 1) {
                        data.shiftBytes(8);
                    }
                } else {
                    revert("not support ChangesTrieSignal type");
                }
            } else {
                revert("not support digest type");
            }
        }
    }

    // decodeU32 accepts a byte array representing a SCALE encoded integer and performs SCALE decoding of the smallint
    function decodeU32(Input.Data memory data) internal pure returns (uint32) {
        uint8 b0 = data.decodeU8();
        uint8 mode = b0 & 3;
        require(mode <= 2, "scale decode not support");
        if (mode == 0) {
            return uint32(b0) >> 2;
        } else if (mode == 1) {
            uint8 b1 = data.decodeU8();
            uint16 v = uint16(b0) | (uint16(b1) << 8);
            return uint32(v) >> 2;
        } else if (mode == 2) {
            uint8 b1 = data.decodeU8();
            uint8 b2 = data.decodeU8();
            uint8 b3 = data.decodeU8();
            uint32 v = uint32(b0) |
                (uint32(b1) << 8) |
                (uint32(b2) << 16) |
                (uint32(b3) << 24);
            return v >> 2;
        }
    }

    function decodeCompactU8aOffset(bytes1 input0) public pure returns (uint8) {
        bytes1 flag = input0 & bytes1(hex"03");
        if (flag == hex"00") {
            return 1;
        } else if (flag == hex"01") {
            return 2;
        } else if (flag == hex"02") {
            return 4;
        }
        uint8 offset = (uint8(input0) >> 2) + 4 + 1;
        return offset;
    }
}
