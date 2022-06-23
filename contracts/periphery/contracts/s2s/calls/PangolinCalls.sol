// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./share/SystemCalls.sol";
import "../types/PalletEthereum.sol";
import "@darwinia/contracts-utils/contracts/SafeMath.sol";

library PangolinCalls {
    using SafeMath for uint256;

    // According to the EVM gas benchmark, 1 gas ~= 40_000 weight.
    uint64 public constant WEIGHT_PER_GAS = 40_000;

    function system_remark(bytes memory remark)
        internal
        pure
        returns (bytes memory, uint64)
    {
        return SystemCalls.remark(remark);
    }

    function system_remarkWithEvent(bytes memory remark)
        internal
        pure
        returns (bytes memory, uint64)
    {
        return SystemCalls.remarkWithEvent(remark);
    }

    function ethereum_messageTransact(
        uint256 gasLimit,
        address to,
        bytes memory input
    ) internal pure returns (bytes memory, uint64) {
        PalletEthereum.MessageTransactCall memory call = PalletEthereum
            .MessageTransactCall(
                // the call index of message_transact
                0x2901,
                // the evm transaction to transact
                PalletEthereum.buildTransactionV2ForMessageTransact(
                    gasLimit,
                    to,
                    input
                )
            );
        uint256 weight = gasLimit.mul(WEIGHT_PER_GAS);
        return (PalletEthereum.encodeMessageTransactCall(call), uint64(weight));
    }
}
