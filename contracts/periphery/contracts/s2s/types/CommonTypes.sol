// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";

library CommonTypes {
    struct Relayer {
        bytes32 id;
        uint128 collateral;
        uint128 fee;
    }

    // 64 bytes
    function decodeRelayer(bytes memory data)
        internal
        pure
        returns (Relayer memory)
    {
        require(data.length >= 64, "The data length of the decoding relayer is not enough");

        bytes32 id = Bytes.toBytes32(Bytes.substr(data, 0, 32));
        uint128 collateral = uint128(
            Bytes.toBytes16(Bytes.substr(data, 32, 16), 0)
        );
        uint128 fee = uint128(Bytes.toBytes16(Bytes.substr(data, 32, 16), 0));

        return Relayer(id, collateral, fee);
    }

    function getLastRelayerFromVec(bytes memory data)
        internal
        pure
        returns (Relayer memory)
    {
        (uint256 length, uint8 mode) = ScaleCodec.decodeUintCompact(
            data
        );
        uint8 compactLength = 2**mode;

        require(mode < 3, "Wrong compact mode"); // Now, mode 3 is not supported yet
        require(data.length >= compactLength + length * 64, "The data length of the decoding relayers is not enough");

        if (length == 0) {
            revert("No relayers are working");
        } else {
            Relayer memory relayer = decodeRelayer(
                Bytes.substr(data, compactLength + 64 * (length - 1))
            );
            return relayer;
        }
    }
}
