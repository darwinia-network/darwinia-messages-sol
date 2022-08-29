// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./CommonTypes.sol";

library PalletEthereumXcm {
    ///////////////////////
    // Calls
    ///////////////////////
    struct TransactCall {
        bytes2 callIndex;
        EthereumXcmTransaction transaction;
    }

    function encodeTransactCall(TransactCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _call.callIndex,
                encodeEthereumXcmTransaction(_call.transaction)
            );
    }

    function buildTransactCall(
        bytes2 _callIndex,
        uint256 _gasLimit,
        address _to,
        uint256 _value,
        bytes memory _input
    ) internal pure returns (bytes memory) {
        PalletEthereumXcm.AccessListType memory accessList;
        accessList.some = false;

        PalletEthereumXcm.TransactCall memory transactCall = PalletEthereumXcm
            .TransactCall(
                _callIndex,
                PalletEthereumXcm.EthereumXcmTransaction(
                    1, // V2
                    PalletEthereumXcm.EthereumXcmTransactionV2(
                        _gasLimit,
                        PalletEthereumXcm.TransactionAction(
                            0, // 0: Call, 1: Create
                            _to
                        ),
                        _value,
                        _input,
                        accessList
                    )
                )
            );

        return PalletEthereumXcm.encodeTransactCall(transactCall);
    }

    ///////////////////////
    // Types
    ///////////////////////
    struct EthereumXcmTransaction {
        uint8 enumItemIndex;
        EthereumXcmTransactionV2 transaction;
    }

    function encodeEthereumXcmTransaction(EthereumXcmTransaction memory _tx)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _tx.enumItemIndex,
                encodeEthereumXcmTransactionV2(_tx.transaction)
            );
    }

    struct EthereumXcmTransactionV2 {
        uint256 gasLimit;
        TransactionAction action;
        uint256 value;
        bytes input;
        AccessListType accessList;
    }

    function encodeEthereumXcmTransactionV2(EthereumXcmTransactionV2 memory _tx)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                ScaleCodec.encode256(_tx.gasLimit),
                encodeTransactionAction(_tx.action),
                ScaleCodec.encode256(_tx.value),
                ScaleCodec.encodeBytes(_tx.input),
                encodeAccessListType(_tx.accessList)
            );
    }

    struct TransactionAction {
        uint8 enumItemIndex;
        address h160;
    }

    function encodeTransactionAction(TransactionAction memory _action)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_action.enumItemIndex, _action.h160);
    }

    // struct AccessListTypeNone {

    // }

    struct AccessListType {
        bool some; // true: Some, false: None
        TupleOfH160AndVecOfH256[] arr;
    }

    struct TupleOfH160AndVecOfH256 {
        address h160;
        bytes32[] vecOfH256;
    }

    function encodeAccessListType(AccessListType memory _accessList)
        internal
        pure
        returns (bytes memory)
    {
        if (_accessList.some) {
            bytes memory data = hex"01";
            data = abi.encodePacked(data, ScaleCodec.encodeUintCompact(_accessList.arr.length));
            for (uint i = 0; i < _accessList.arr.length; i++) {
                TupleOfH160AndVecOfH256 memory tuple = _accessList.arr[i];
                data = abi.encodePacked(data, tuple.h160);
                data = abi.encodePacked(data, ScaleCodec.encodeUintCompact(tuple.vecOfH256.length));
                for (uint j = 0; j < tuple.vecOfH256.length; j++) {
                    data = abi.encodePacked(data, tuple.vecOfH256[j]);
                }
            }
            return data;
        } else {
            return hex"00";
        }
    }
}
