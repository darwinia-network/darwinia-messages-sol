// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./CommonTypes.sol";

library PalletEthereum {
    struct TransactCall {
        bytes2 callIndex;
        EnumItemTransactionV2WithLegacyTransaction transaction;
    }

    function encodeTransactCall(TransactCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _call.callIndex,
                encodeEnumItemTransactionV2WithLegacyTransaction(
                    _call.transaction
                )
            );
    }

    struct MessageTransactCall {
        bytes2 callIndex;
        EnumItemTransactionV2WithLegacyTransaction transaction;
    }

    function encodeMessageTransactCall(MessageTransactCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _call.callIndex,
                encodeEnumItemTransactionV2WithLegacyTransaction(
                    _call.transaction
                )
            );
    }

    struct EnumItemTransactionActionWithAddress {
        uint8 index;
        address h160;
    }

    function encodeEnumItemTransactionActionWithAddress(
        EnumItemTransactionActionWithAddress memory _item
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_item.index, _item.h160);
    }

    struct LegacyTransaction {
        uint256 nonce;
        uint256 gasPrice;
        uint256 gasLimit;
        EnumItemTransactionActionWithAddress action;
        uint256 value;
        bytes input;
        uint64 v;
        bytes32 r;
        bytes32 s;
    }

    function encodeLegacyTransaction(LegacyTransaction memory _transaction)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                ScaleCodec.encode256(_transaction.nonce),
                ScaleCodec.encode256(_transaction.gasPrice),
                ScaleCodec.encode256(_transaction.gasLimit),
                encodeEnumItemTransactionActionWithAddress(_transaction.action),
                ScaleCodec.encode256(_transaction.value),
                ScaleCodec.encodeBytes(_transaction.input),
                ScaleCodec.encode64(_transaction.v),
                _transaction.r,
                _transaction.s
            );
    }

    struct EnumItemTransactionV2WithLegacyTransaction {
        uint8 index;
        LegacyTransaction legacyTransaction;
    }

    function encodeEnumItemTransactionV2WithLegacyTransaction(
        EnumItemTransactionV2WithLegacyTransaction memory _item
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                _item.index,
                encodeLegacyTransaction(_item.legacyTransaction)
            );
    }

    function buildTransactionV2(
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _to,
        uint256 _value,
        uint64 _smartChainId,
        bytes memory _input
    )
        internal
        pure
        returns (EnumItemTransactionV2WithLegacyTransaction memory)
    {
        LegacyTransaction memory transaction = LegacyTransaction(
            _nonce,
            _gasPrice,
            _gasLimit,
            PalletEthereum.EnumItemTransactionActionWithAddress(
                0, // enum index
                _to
            ),
            _value,
            _input,
            _smartChainId * 2 + 36, // v
            0x3737373737373737373737373737373737373737373737373737373737373737, // r
            0x3737373737373737373737373737373737373737373737373737373737373737 // s
        );

        return
            EnumItemTransactionV2WithLegacyTransaction(
                0, // enum index
                transaction // legacyTransaction
            );
    }

    function buildTransactionV2ForMessageTransact(
        uint256 _gasLimit,
        address _to,
        uint64 _smartChainId,
        bytes memory _input
    )
        internal
        pure
        returns (EnumItemTransactionV2WithLegacyTransaction memory)
    {
        // nonce and gasPrice will be set by target chain
        return buildTransactionV2(0, 0, _gasLimit, _to, 0, _smartChainId, _input);
    }
}
