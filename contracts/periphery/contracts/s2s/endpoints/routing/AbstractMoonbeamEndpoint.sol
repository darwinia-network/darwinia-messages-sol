// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../endpoints/Executable.sol";
import "../../SmartChainXLib.sol";
import "../../types/PalletEthereum.sol";
import "../../types/PalletBridgeMessages.sol";
import "../../precompiles/moonbeam/XcmTransactorV1.sol";

abstract contract AbstractMoonbeamEndpoint is Executable {
    // Target params
    address public targetEndpoint;
    uint64 public targetSmartChainId;
    bytes2 public targetMessageTransactCallIndex;
    uint64 public targetWeightPerGas = 40_000; // 1 gas ~= 40_000 weight

    // router params
    bytes2 public routerSendMessageCallIndex;
    bytes4 public routerOutboundLaneId;
    bytes4 public routerParachainId;

    // Local params
    address public feeLocationAddress;

    event TargetInputGenerated(bytes);
    event TargetTransactCallGenerated(bytes);
    event LcmpMessngeGenerated(bytes);

    ///////////////////////////////
    // Outbound
    ///////////////////////////////
    function _targetExecute(
        uint32 _tgtSpecVersion,
        address _callReceiver,
        bytes calldata _callPayload,
        uint256 _gasLimit,
        //
        uint128 _deliveryAndDispatchFee
    ) internal {
        // solidity call that will be executed on crab smart chain
        bytes memory tgtInput = abi.encodeWithSelector(
            this.execute.selector,
            _callReceiver,
            _callPayload
        );

        emit TargetInputGenerated(tgtInput);

        // transact dispatch call that will be executed on crab chain
        bytes memory tgtTransactCallEncoded = PalletEthereum
            .encodeMessageTransactCall(
                PalletEthereum.MessageTransactCall(
                    targetMessageTransactCallIndex,
                    PalletEthereum.buildTransactionV2ForMessageTransact(
                        _gasLimit,
                        targetEndpoint,
                        targetSmartChainId,
                        tgtInput
                    )
                )
            );

        emit TargetTransactCallGenerated(tgtTransactCallEncoded);

        uint64 tgtTransactCallWeight = uint64(_gasLimit * targetWeightPerGas);

        // send_message dispatch call that will be executed on crab parachain
        bytes memory message = SmartChainXLib.buildMessage(
            _tgtSpecVersion,
            tgtTransactCallWeight,
            tgtTransactCallEncoded
        );

        emit LcmpMessngeGenerated(message);

        bytes memory routerSendMessageCallEncoded = PalletBridgeMessages
            .encodeSendMessageCall(
                PalletBridgeMessages.SendMessageCall(
                    routerSendMessageCallIndex,
                    routerOutboundLaneId,
                    message,
                    _deliveryAndDispatchFee
                )
            );


        uint64 routerSendMessageCallWeight = uint64(
            1617480000 + (1383867 * (1024 + message.length)) / 1024
        );

        // remote call send_message from moonbeam
        XcmTransactorV1.transactThroughSigned(
            routerParachainId,
            feeLocationAddress,
            routerSendMessageCallWeight,
            routerSendMessageCallEncoded
        );
    }

    // origin from moonbase to pangolin, A2
    function getDerivedAccountId() external view returns (bytes32) {
        bytes32 derivedSubstrateAddress = AccountId.deriveSubstrateAddress(
            address(this)
        );
       
        return derivedSubstrateAddress;
    }

    ///////////////////////////////
    // Setters
    ///////////////////////////////
    function _setTargetEndpoint(
        bytes4 _targetChainId,
        bytes4 _parachainId,
        address _targetEndpoint
    ) internal {
        targetEndpoint = _targetEndpoint;

        derivedMessageSender = SmartChainXLib
            .deriveSenderFromSmartChainOnMoonbeam(
                _targetChainId,
                _targetEndpoint,
                _parachainId
            );
    }

    function _setTargetMessageTransactCallIndex(
        bytes2 _targetMessageTransactCallIndex
    ) internal {
        targetMessageTransactCallIndex = _targetMessageTransactCallIndex;
    }

    function _setTargetSmartChainId(uint64 _targetSmartChainId) internal {
        targetSmartChainId = _targetSmartChainId;
    }

    function _setTargetWeightPerGas(uint64 _targetWeightPerGas) internal {
        targetWeightPerGas = _targetWeightPerGas;
    }

    function _setRouterSendMessageCallIndex(bytes2 _routerSendMessageCallIndex)
        internal
    {
        routerSendMessageCallIndex = _routerSendMessageCallIndex;
    }

    function _setRouterOutboundLaneId(bytes4 _routerOutboundLaneId) internal {
        routerOutboundLaneId = _routerOutboundLaneId;
    }

    function _setFeeLocationAddress(address _feeLocationAddress) internal {
        feeLocationAddress = _feeLocationAddress;
    }
}
