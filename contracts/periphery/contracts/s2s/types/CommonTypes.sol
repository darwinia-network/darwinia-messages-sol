// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "hardhat/console.sol";

library CommonTypes {
    function decodeUint128(bytes memory data) internal pure returns (uint128) {
        require(data.length >= 16, "The data is not right");
        bytes memory reversed = Bytes.reverse(data);
        return uint128(Bytes.toBytes16(reversed, 0));
    }

    function decodeUint64(bytes memory data) internal pure returns (uint64) {
        require(data.length >= 8, "The data is not right");
        bytes memory reversed = Bytes.reverse(data);
        return uint64(Bytes.toBytes8(reversed, 0));
    }

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
        require(
            data.length >= 64,
            "The data length of the decoding relayer is not enough"
        );

        bytes32 id = Bytes.toBytes32(Bytes.substr(data, 0, 32));

        uint128 collateral = decodeUint128(Bytes.substr(data, 32, 16));

        uint128 fee = decodeUint128(Bytes.substr(data, 48, 16));

        return Relayer(id, collateral, fee);
    }

    function getLastRelayerFromVec(bytes memory data)
        internal
        pure
        returns (Relayer memory)
    {
        (uint256 length, uint8 mode) = ScaleCodec.decodeUintCompact(data);
        uint8 compactLength = uint8(2**mode);

        require(mode < 3, "Wrong compact mode"); // Now, mode 3 is not supported yet
        require(
            data.length >= compactLength + length * 64,
            "The data length of the decoding relayers is not enough"
        );

        if (length == 0) {
            revert("No relayers are working");
        } else {
            Relayer memory relayer = decodeRelayer(
                Bytes.substr(data, compactLength + 64 * (length - 1))
            );
            return relayer;
        }
    }

    struct OutboundLaneData {
        uint64 oldestUnprunedNonce;
        uint64 latestReceivedNonce;
        uint64 latestGeneratedNonce;
    }

    // 24 bytes
    function decodeOutboundLaneData(bytes memory data)
        internal
        pure
        returns (OutboundLaneData memory)
    {
        require(
            data.length >= 24,
            "The data length of the decoding OutboundLaneData is not enough"
        );

        uint64 oldestUnprunedNonce = decodeUint64(Bytes.substr(data, 0, 8));
        uint64 latestReceivedNonce = decodeUint64(Bytes.substr(data, 8, 8));
        uint64 latestGeneratedNonce = decodeUint64(Bytes.substr(data, 16, 8));

        return
            OutboundLaneData(
                oldestUnprunedNonce,
                latestReceivedNonce,
                latestGeneratedNonce
            );
    }
}
