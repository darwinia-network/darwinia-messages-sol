// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "hardhat/console.sol";

library CommonTypes {
    struct EnumItemWithAccountId {
        uint8 index;
        address accountId;
    }

    function encodeEnumItemWithAccountId(
        EnumItemWithAccountId memory _item
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_item.index, _item.accountId);
    }

    struct EnumItemWithNull {
        uint8 index;
    }

    function encodeEnumItemWithNull(
        EnumItemWithNull memory _item
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_item.index);
    }

    ////////////////////////////////////
    // BitVecU8
    ////////////////////////////////////
    function ceilDivide(uint a, uint b) internal pure returns (uint) {
        if (a % b == 0) {
            return a / b;
        } else {
            return a / b + 1;
        }
    }

    // bits: bit amount used, 1: true, 0: false
    // bytesLength: bytes used by bits
    // result: the bytes
    struct BitVecU8 {
        uint bits;
        bytes result;
        uint bytesLength;
    }

    function decodeBitVecU8(
        bytes memory _data
    ) internal pure returns (BitVecU8 memory) {
        (uint256 bits, uint8 mode) = ScaleCodec.decodeUintCompact(_data);
        uint prefixLength = uint8(2 ** mode);
        uint bytesLength = ceilDivide(bits, 8);
        require(
            _data.length >= prefixLength + bytesLength,
            "The data is not enough to decode BitVecU8"
        );
        return
            BitVecU8(
                bits,
                Bytes.substr(_data, prefixLength, bytesLength),
                prefixLength + bytesLength
            );
    }

    ////////////////////////////////////
    // Relayer
    ////////////////////////////////////
    struct Relayer {
        bytes20 id;
        uint128 collateral;
        uint128 fee;
    }

    // 52 bytes
    function decodeRelayer(
        bytes memory _data
    ) internal pure returns (Relayer memory) {
        require(_data.length >= 52, "The data is not enough to decode Relayer");

        bytes20 id = bytes20(Bytes.substr(_data, 0, 20));

        uint128 collateral = ScaleCodec.decodeUint128(
            Bytes.substr(_data, 20, 16)
        );

        uint128 fee = ScaleCodec.decodeUint128(Bytes.substr(_data, 36, 16));

        return Relayer(id, collateral, fee);
    }

    function getLastRelayerFromVec(
        bytes memory _data
    ) internal pure returns (Relayer memory) {
        // Option::None
        require(_data.length > 0, "No relayers");

        // Option::Some(Reayler[])
        // _data checking
        (uint256 relayersCount, uint8 mode) = ScaleCodec.decodeUintCompact(
            _data
        );
        require(relayersCount > 0, "No relayers");
        require(mode < 3, "Wrong compact mode"); // Now, mode 3 is not supported yet
        uint8 lengthOfPrefixBytes = uint8(2 ** mode);
        require(
            _data.length >= lengthOfPrefixBytes + relayersCount * 52,
            "No enough data"
        );

        // get the bytes of the last Relayer, then decode
        Relayer memory relayer = decodeRelayer(
            Bytes.substr(_data, lengthOfPrefixBytes + 52 * (relayersCount - 1))
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
    function decodeOutboundLaneData(
        bytes memory _data
    ) internal pure returns (OutboundLaneData memory) {
        require(
            _data.length >= 24,
            "The data is not enough to decode OutboundLaneData"
        );

        uint64 oldestUnprunedNonce = ScaleCodec.decodeUint64(
            Bytes.substr(_data, 0, 8)
        );
        uint64 latestReceivedNonce = ScaleCodec.decodeUint64(
            Bytes.substr(_data, 8, 8)
        );
        uint64 latestGeneratedNonce = ScaleCodec.decodeUint64(
            Bytes.substr(_data, 16, 8)
        );

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
        BitVecU8 dispatchResults;
    }

    function decodeDeliveredMessages(
        bytes memory _data
    ) internal pure returns (DeliveredMessages memory) {
        uint64 begin = ScaleCodec.decodeUint64(Bytes.substr(_data, 0, 8));
        uint64 end = ScaleCodec.decodeUint64(Bytes.substr(_data, 8, 8));
        BitVecU8 memory dispatchResults = decodeBitVecU8(
            Bytes.substr(_data, 16)
        );

        return DeliveredMessages(begin, end, dispatchResults);
    }

    function getBytesLengthOfDeliveredMessages(
        DeliveredMessages memory deliveredMessages
    ) internal pure returns (uint) {
        return 16 + deliveredMessages.dispatchResults.bytesLength;
    }

    ////////////////////////////////////
    // UnrewardedRelayer
    ////////////////////////////////////
    struct UnrewardedRelayer {
        address relayer;
        DeliveredMessages messages;
    }

    function decodeUnrewardedRelayer(
        bytes memory _data
    ) internal pure returns (UnrewardedRelayer memory) {
        address relayer = toAddress(_data, 0);
        DeliveredMessages memory messages = decodeDeliveredMessages(
            Bytes.substr(_data, 20)
        );

        return UnrewardedRelayer(relayer, messages);
    }

    function getBytesLengthOfUnrewardedRelayer(
        UnrewardedRelayer memory unrewardedRelayer
    ) internal pure returns (uint) {
        uint bytesLengthOfmessages = getBytesLengthOfDeliveredMessages(
            unrewardedRelayer.messages
        );
        return 20 + bytesLengthOfmessages;
    }

    function toAddress(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
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

    function decodeInboundLaneData(
        bytes memory _data
    ) internal pure returns (InboundLaneData memory) {
        (uint256 numberOfRelayers, uint8 mode) = ScaleCodec.decodeUintCompact(
            _data
        );
        require(mode < 3, "Wrong compact mode"); // Now, mode 3 is not supported yet
        uint consumedLength = uint8(2 ** mode);

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
        result.lastConfirmedNonce = ScaleCodec.decodeUint64(
            Bytes.substr(_data, consumedLength)
        );

        return result;
    }

    function getLastDeliveredNonceFromInboundLaneData(
        bytes memory _data
    ) internal pure returns (uint64) {
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
        uint64 weightRefTime;
        uint64 weightProofSize;
        EnumItemWithAccountId origin;
        EnumItemWithNull dispatchFeePayment;
        bytes call;
    }

    function encodeMessage(
        Message memory _message
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                ScaleCodec.encode32(_message.specVersion),
                // weight
                ScaleCodec.encodeUintCompact(_message.weightRefTime),
                ScaleCodec.encodeUintCompact(_message.weightProofSize),
                // origin
                _message.origin.index,
                _message.origin.accountId,
                // dispatchFeePayment
                _message.dispatchFeePayment.index,
                ScaleCodec.encodeBytes(_message.call)
            );
    }
}
