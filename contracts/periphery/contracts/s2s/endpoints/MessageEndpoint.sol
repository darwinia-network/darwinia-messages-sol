// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../SmartChainXLib.sol";
import "./Executable.sol";
import "./RemoteDispatchEndpoint.sol";
import "../types/PalletEthereum.sol";
import "../types/PalletEthereumXcm.sol";

// TODO: rename: RemoteExecuteEndpoint
abstract contract MessageEndpoint is RemoteDispatchEndpoint, Executable {
    address public remoteEndpoint;
    bytes2 public remoteMessageTransactCallIndex;
    uint64 public remoteSmartChainId; // remote smart chain id
    uint64 public remoteWeightPerGas = 40_000; // 1 gas ~= 40_000 weight

    ///////////////////////////////
    // Outbound
    ///////////////////////////////
    function _remoteExecute(
        uint32 tgtSpecVersion,
        address callReceiver,
        bytes calldata callPayload,
        uint256 gasLimit
    ) internal returns (uint256) {
        bytes memory input = abi.encodeWithSelector(
            this.execute.selector,
            callReceiver,
            callPayload
        );

        // build the TransactCall
        PalletEthereum.MessageTransactCall memory tgtTransactCall = PalletEthereum
            .MessageTransactCall(
                // the call index of message_transact
                remoteMessageTransactCallIndex,
                // the evm transaction to transact
                PalletEthereum.buildTransactionV2ForMessageTransact(
                    gasLimit,
                    remoteEndpoint,
                    remoteSmartChainId,
                    input
                )
            );

        bytes memory tgtTransactCallEncoded = PalletEthereum
            .encodeMessageTransactCall(tgtTransactCall);

        uint64 tgtTransactCallWeight = uint64(gasLimit * remoteWeightPerGas);

        // dispatch the TransactCall
        return
            _remoteDispatch(
                tgtSpecVersion,
                tgtTransactCallEncoded,
                tgtTransactCallWeight
            );
    }

    ///////////////////////////////
    // Setters
    ///////////////////////////////
    function _setRemoteEndpoint(bytes4 _remoteChainId, address _remoteEndpoint)
        internal
    {
        remoteEndpoint = _remoteEndpoint;
        derivedMessageSender = SmartChainXLib.deriveSenderFromRemote(
            _remoteChainId,
            _remoteEndpoint
        );
    }

    function _setRemoteMessageTransactCallIndex(
        bytes2 _remoteMessageTransactCallIndex
    ) internal {
        remoteMessageTransactCallIndex = _remoteMessageTransactCallIndex;
    }

    function _setRemoteWeightPerGas(uint64 _remoteWeightPerGas) internal {
        remoteWeightPerGas = _remoteWeightPerGas;
    }

    function _setRemoteSmartChainId(uint64 _remoteSmartChainId) internal {
        remoteSmartChainId = _remoteSmartChainId;
    }
}
