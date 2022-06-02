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

    function encodeTransactCall(TransactCall memory call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                call.callIndex,
                encodeEnumItemTransactionV2WithLegacyTransaction(
                    call.transaction
                )
            );
    }

    struct EnumItemTransactionActionWithAddress {
        uint8 index;
        address h160;
    }

    function encodeEnumItemTransactionActionWithAddress(
        EnumItemTransactionActionWithAddress memory item
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(item.index, item.h160);
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

    function encodeLegacyTransaction(LegacyTransaction memory transaction)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                ScaleCodec.encode256(transaction.nonce),
                ScaleCodec.encode256(transaction.gasPrice),
                ScaleCodec.encode256(transaction.gasLimit),
                encodeEnumItemTransactionActionWithAddress(transaction.action),
                ScaleCodec.encode256(transaction.value),
                ScaleCodec.encodeBytes(transaction.input),
                ScaleCodec.encode64(transaction.v),
                transaction.r,
                transaction.s
            );
    }

    struct EnumItemTransactionV2WithLegacyTransaction {
        uint8 index;
        LegacyTransaction legacyTransaction;
    }

    function encodeEnumItemTransactionV2WithLegacyTransaction(
        EnumItemTransactionV2WithLegacyTransaction memory item
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                item.index,
                encodeLegacyTransaction(item.legacyTransaction)
            );
    }

    function buildTransactionV2(
        uint256 nonce,
        uint256 gasPrice,
        uint256 gasLimit,
        address to,
        uint256 value,
        bytes memory input
    )
        internal
        pure
        returns (EnumItemTransactionV2WithLegacyTransaction memory)
    {
        LegacyTransaction memory transaction = LegacyTransaction(
            nonce,
            gasPrice,
            gasLimit,
            PalletEthereum.EnumItemTransactionActionWithAddress(
                0, // enum index
                to
            ),
            value,
            input,
            0, // v
            0, // r
            0 // s
        );

        return
            EnumItemTransactionV2WithLegacyTransaction(
                0, // enum index
                transaction // legacyTransaction
            );
    }
}
