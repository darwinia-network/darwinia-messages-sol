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

    struct EnumItemWithAccountId {
        uint8 index;
        bytes32 accountId;
    }

    function encodeEnumItemWithAccountId(EnumItemWithAccountId memory item)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(item.index, item.accountId);
    }

    struct EnumItemWithNull {
        uint8 index;
    }

    function encodeEnumItemWithNull(EnumItemWithNull memory item)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(item.index);
    }

    ////////////////////////////////////
    // Relayer
    ////////////////////////////////////
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
            "The data length to decode Relayeris not enough"
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
            "The data length to decode LastRelayerFromVec is not enough"
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

    ////////////////////////////////////
    // OutboundLaneData
    ////////////////////////////////////
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

    ////////////////////////////////////
    // DeliveredMessages
    ////////////////////////////////////
    struct DeliveredMessages {
        uint64 begin;
        uint64 end;
        bytes1 dispatch_results;
    }

    function decodeDeliveredMessages(bytes memory data)
        internal
        pure
        returns (DeliveredMessages memory)
    {
        require(data.length >= 17, "The data length is not enough");

        uint64 begin = decodeUint64(Bytes.substr(data, 0, 8));
        uint64 end = decodeUint64(Bytes.substr(data, 8, 8));
        bytes1 dispatch_results = data[16];

        return DeliveredMessages(begin, end, dispatch_results);
    }

    ////////////////////////////////////
    // UnrewardedRelayer
    ////////////////////////////////////
    struct UnrewardedRelayer {
        bytes32 relayer;
        DeliveredMessages messages;
    }

    function decodeUnrewardedRelayer(bytes memory data)
        internal
        pure
        returns (UnrewardedRelayer memory)
    {
        require(data.length >= 49, "The data length is not enough");

        bytes32 relayer = Bytes.toBytes32(Bytes.substr(data, 0, 32));
        DeliveredMessages memory messages = decodeDeliveredMessages(
            Bytes.substr(data, 32)
        );

        return UnrewardedRelayer(relayer, messages);
    }

    ////////////////////////////////////
    // InboundLaneData
    ////////////////////////////////////
    // struct InboundLaneData {
    //     VecDeque<UnrewardedRelayer> relayers;
    //     uint64 last_confirmed_nonce;
    // }
    function getLastDeliveredNonceFromInboundLaneData(bytes memory data)
        internal
        pure
        returns (uint64)
    {
        (uint256 length, uint8 mode) = ScaleCodec.decodeUintCompact(data);
        require(mode < 3, "Wrong compact mode"); // Now, mode 3 is not supported yet
        uint8 compactLength = uint8(2**mode);
        require(
            data.length >= compactLength + length * 49 + 8,
            "The data length is not enough to decode InboundLaneData"
        );

        uint64 lastConfirmedNonce = decodeUint64(Bytes.substr(data, compactLength + 49 * length));
        if (length == 0) {
            return lastConfirmedNonce;
        } else {
            UnrewardedRelayer memory relayer = decodeUnrewardedRelayer(
                Bytes.substr(data, compactLength + 49 * (length - 1))
            );
            return relayer.messages.end;
        } 
    }

    ////////////////////////////////////
    // Message
    ////////////////////////////////////
    struct Message {
        uint32 specVersion;
        uint64 weight;
        EnumItemWithAccountId origin;
        EnumItemWithNull dispatchFeePayment;
        bytes call;
    }

    function encodeMessage(Message memory msg1)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                ScaleCodec.encode32(msg1.specVersion),
                ScaleCodec.encode64(msg1.weight),
                encodeEnumItemWithAccountId(msg1.origin),
                encodeEnumItemWithNull(msg1.dispatchFeePayment),
                ScaleCodec.encodeBytes(msg1.call)
            );
    }
}
