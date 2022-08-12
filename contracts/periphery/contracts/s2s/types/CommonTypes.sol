// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "hardhat/console.sol";

library CommonTypes {
    function decodeUint128(bytes memory _data) internal pure returns (uint128) {
        require(_data.length >= 16, "The data is not enough");
        bytes memory reversed = Bytes.reverse(_data);
        return uint128(Bytes.toBytes16(reversed, 0));
    }

    function decodeUint64(bytes memory _data) internal pure returns (uint64) {
        require(_data.length >= 8, "The data is not enough");
        bytes memory reversed = Bytes.reverse(_data);
        return uint64(Bytes.toBytes8(reversed, 0));
    }

    struct EnumItemWithAccountId {
        uint8 index;
        bytes32 accountId;
    }

    function encodeEnumItemWithAccountId(EnumItemWithAccountId memory _item)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_item.index, _item.accountId);
    }

    struct EnumItemWithNull {
        uint8 index;
    }

    function encodeEnumItemWithNull(EnumItemWithNull memory _item)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_item.index);
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
    function decodeRelayer(bytes memory _data)
        internal
        pure
        returns (Relayer memory)
    {
        require(
            _data.length >= 64,
            "The data is not enough to decode Relayer"
        );

        bytes32 id = Bytes.toBytes32(Bytes.substr(_data, 0, 32));

        uint128 collateral = decodeUint128(Bytes.substr(_data, 32, 16));

        uint128 fee = decodeUint128(Bytes.substr(_data, 48, 16));

        return Relayer(id, collateral, fee);
    }

    function getLastRelayerFromVec(bytes memory _data)
        internal
        pure
        returns (Relayer memory)
    {
        // Option::None
        require(_data.length > 0, "No relayers");

        // Option::Some(Reayler[])
        // _data checking
        (uint256 relayersCount, uint8 mode) = ScaleCodec.decodeUintCompact(_data);
        require(relayersCount > 0, "No relayers");
        require(mode < 3, "Wrong compact mode"); // Now, mode 3 is not supported yet
        uint8 lengthOfPrefixBytes = uint8(2**mode);
        require(
            _data.length >= lengthOfPrefixBytes + relayersCount * 64,
            "No enough data"
        );

        // get the bytes of the last Relayer, then decode
        Relayer memory relayer = decodeRelayer(
            Bytes.substr(_data, lengthOfPrefixBytes + 64 * (relayersCount - 1))
        );
        return relayer;
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
    function decodeOutboundLaneData(bytes memory _data)
        internal
        pure
        returns (OutboundLaneData memory)
    {
        require(
            _data.length >= 24,
            "The data is not enough to decode OutboundLaneData"
        );

        uint64 oldestUnprunedNonce = decodeUint64(Bytes.substr(_data, 0, 8));
        uint64 latestReceivedNonce = decodeUint64(Bytes.substr(_data, 8, 8));
        uint64 latestGeneratedNonce = decodeUint64(Bytes.substr(_data, 16, 8));

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

    function decodeDeliveredMessages(bytes memory _data)
        internal
        pure
        returns (DeliveredMessages memory)
    {
        require(_data.length >= 17, "The data is not enough");

        uint64 begin = decodeUint64(Bytes.substr(_data, 0, 8));
        uint64 end = decodeUint64(Bytes.substr(_data, 8, 8));
        bytes1 dispatch_results = _data[16];

        return DeliveredMessages(begin, end, dispatch_results);
    }

    ////////////////////////////////////
    // UnrewardedRelayer
    ////////////////////////////////////
    struct UnrewardedRelayer {
        bytes32 relayer;
        DeliveredMessages messages;
    }

    function decodeUnrewardedRelayer(bytes memory _data)
        internal
        pure
        returns (UnrewardedRelayer memory)
    {
        require(_data.length >= 49, "The data is not enough");

        bytes32 relayer = Bytes.toBytes32(Bytes.substr(_data, 0, 32));
        DeliveredMessages memory messages = decodeDeliveredMessages(
            Bytes.substr(_data, 32)
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
    function getLastDeliveredNonceFromInboundLaneData(bytes memory _data)
        internal
        pure
        returns (uint64)
    {
        (uint256 length, uint8 mode) = ScaleCodec.decodeUintCompact(_data);
        require(mode < 3, "Wrong compact mode"); // Now, mode 3 is not supported yet
        uint8 compactLength = uint8(2**mode);
        require(
            _data.length >= compactLength + length * 49 + 8,
            "The data is not enough to decode InboundLaneData"
        );

        uint64 lastConfirmedNonce = decodeUint64(Bytes.substr(_data, compactLength + 49 * length));
        if (length == 0) {
            return lastConfirmedNonce;
        } else {
            UnrewardedRelayer memory relayer = decodeUnrewardedRelayer(
                Bytes.substr(_data, compactLength + 49 * (length - 1))
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

    function encodeMessage(Message memory _message)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                ScaleCodec.encode32(_message.specVersion),
                ScaleCodec.encode64(_message.weight),
                encodeEnumItemWithAccountId(_message.origin),
                encodeEnumItemWithNull(_message.dispatchFeePayment),
                ScaleCodec.encodeBytes(_message.call)
            );
    }
}
