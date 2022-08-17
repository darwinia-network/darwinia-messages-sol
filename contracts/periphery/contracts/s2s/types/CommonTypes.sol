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
    // BitVecU8
    ////////////////////////////////////
    function ceilDivide(uint a, uint b) internal pure returns (uint) {
        if (a % b == 0) {
            return uint(a) / b;
        } else {
            return uint(a) / b + 1;
        }
    }

    struct BitVecU8 {
        uint bits;
        bytes result;
    }

    function decodeBitVecU8(bytes memory _data)
        internal
        pure
        returns (BitVecU8 memory)
    {
        (uint256 bits, uint8 mode) = ScaleCodec.decodeUintCompact(_data);
        uint prefixLength = uint8(2**mode);
        uint bytesLength = ceilDivide(bits, 8);
        require(
            _data.length >= prefixLength + bytesLength,
            "The data is not enough to decode BitVecU8"
        );
        return BitVecU8(bits, Bytes.substr(_data, prefixLength, bytesLength));
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
        require(_data.length >= 64, "The data is not enough to decode Relayer");

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
        (uint256 relayersCount, uint8 mode) = ScaleCodec.decodeUintCompact(
            _data
        );
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
        BitVecU8 dispatch_results;
    }

    function decodeDeliveredMessages(bytes memory _data)
        internal
        pure
        returns (DeliveredMessages memory)
    {
        uint64 begin = decodeUint64(Bytes.substr(_data, 0, 8));
        uint64 end = decodeUint64(Bytes.substr(_data, 8, 8));
        BitVecU8 memory dispatch_results = decodeBitVecU8(Bytes.substr(_data, 16));

        return DeliveredMessages(begin, end, dispatch_results);
    }

    function getBytesLengthOfDeliveredMessages(
        DeliveredMessages memory deliveredMessages
    ) internal pure returns (uint) {
        return 16 + deliveredMessages.dispatch_results.result.length;
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
        bytes32 relayer = Bytes.toBytes32(Bytes.substr(_data, 0, 32));
        DeliveredMessages memory messages = decodeDeliveredMessages(
            Bytes.substr(_data, 32)
        );

        return UnrewardedRelayer(relayer, messages);
    }

    function getBytesLengthOfUnrewardedRelayer(
        UnrewardedRelayer memory unrewardedRelayer
    ) internal pure returns (uint) {
        uint bytesLengthOfmessages = getBytesLengthOfDeliveredMessages(
            unrewardedRelayer.messages
        );
        return 32 + bytesLengthOfmessages;
    }

    ////////////////////////////////////
    // InboundLaneData
    ////////////////////////////////////
    // struct InboundLaneData {
    //     VecDeque<UnrewardedRelayer> relayers;
    //     uint64 last_confirmed_nonce;
    // }
    struct InboundLaneData {
        UnrewardedRelayer[] relayers;
        uint64 lastConfirmedNonce;
    }

    function decodeInboundLaneData(bytes memory _data)
        internal
        pure
        returns (InboundLaneData memory)
    {
        (uint256 numberOfRelayers, uint8 mode) = ScaleCodec.decodeUintCompact(
            _data
        );
        require(mode < 3, "Wrong compact mode"); // Now, mode 3 is not supported yet
        uint consumedLength = uint8(2**mode);

        InboundLaneData memory result = InboundLaneData(
            new UnrewardedRelayer[](numberOfRelayers),
            0
        );

        // decode relayers
        for (uint i = 0; i < numberOfRelayers; i++) {
            UnrewardedRelayer memory relayer = decodeUnrewardedRelayer(
                Bytes.substr(_data, consumedLength)
            );
            result.relayers[i] = relayer;
            consumedLength =
                consumedLength +
                getBytesLengthOfUnrewardedRelayer(relayer);
        }

        // decode lastConfirmedNonce
        result.lastConfirmedNonce = decodeUint64(
            Bytes.substr(_data, consumedLength)
        );

        return result;
    }

    function getLastDeliveredNonceFromInboundLaneData(bytes memory _data)
        internal
        pure
        returns (uint64)
    {
        InboundLaneData memory inboundLaneData = decodeInboundLaneData(_data);
        if (inboundLaneData.relayers.length == 0) {
            return inboundLaneData.lastConfirmedNonce;
        } else {
            UnrewardedRelayer memory lastRelayer = inboundLaneData.relayers[
                inboundLaneData.relayers.length - 1
            ];
            return lastRelayer.messages.end;
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
