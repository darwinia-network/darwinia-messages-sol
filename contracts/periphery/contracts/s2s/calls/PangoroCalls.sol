// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./share/SystemCalls.sol";
import "../types/PalletEthereum.sol";

library PangoroCalls {
    // According to the EVM gas benchmark, 1 gas ~= 40_000 weight.
    uint64 public constant WEIGHT_PER_GAS = 40_000;

    // The cap limitation for gas limit, we use 1/5 of max block gas limit
    // The minimum limitations of max block gas limit and considerations of MaxUsableBalanceFromRelayer  fee limit
    // https://github.com/darwinia-network/darwinia-messages-substrate/issues/107#issuecomment-1164185135
    uint64 public constant MAX_GAS_LIMIT = 10_000_000;

    uint64 public constant SMART_CHAIN_ID = 45;

    function system_remark(bytes memory _remark)
        internal
        pure
        returns (bytes memory, uint64)
    {
        return SystemCalls.remark(_remark);
    }

    function system_remarkWithEvent(bytes memory _remark)
        internal
        pure
        returns (bytes memory, uint64)
    {
        (bytes memory call, uint64 weight) = SystemCalls.remarkWithEvent(
            _remark
        );

        require(
            weight <= MAX_GAS_LIMIT * WEIGHT_PER_GAS,
            "The remark is too long"
        );

        return (call, weight);
    }

    function ethereum_messageTransact(
        uint256 _gasLimit,
        address _to,
        bytes memory input
    ) internal pure returns (bytes memory, uint64) {
        require(_gasLimit <= MAX_GAS_LIMIT, "Gas limit is too high");

        PalletEthereum.MessageTransactCall memory call = PalletEthereum
            .MessageTransactCall(
                // the call index of message_transact
                0x1a01,
                // the evm transaction to transact
                PalletEthereum.buildTransactionV2ForMessageTransact(
                    _gasLimit,
                    _to,
                    SMART_CHAIN_ID,
                    input
                )
            );
        uint256 weight = _gasLimit * WEIGHT_PER_GAS;
        return (PalletEthereum.encodeMessageTransactCall(call), uint64(weight));
    }
}
