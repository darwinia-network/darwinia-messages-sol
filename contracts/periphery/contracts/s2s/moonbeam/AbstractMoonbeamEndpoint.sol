// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../SmartChainXLib.sol";
import "../types/PalletEthereum.sol";
import "../precompiles/moonbeam/IXcmTransactorV1.sol";
import "../precompiles/moonbeam/XcmTransactorV1.sol";
import "../types/PalletBridgeMessages.sol";

abstract contract AbstractMoonbeamEndpoint {
    // Remote params
    address public remoteEndpoint;
    uint64 public remoteSmartChainId;
    bytes2 public remoteMessageTransactCallIndex;
    uint64 public remoteWeightPerGas = 40_000; // 1 gas ~= 40_000 weight

    // router params
    bytes2 public routerSendMessageCallIndex;
    bytes4 public routerOutboundLaneId;
    bytes public routerParachainId;

    // Local params
    address public feeLocationAddress;
    address public derivedMessageSender; // message sender derived from remoteEndpoint

    ///////////////////////////////
    // Outbound
    ///////////////////////////////
    function _remoteExecute(
        uint32 _tgtSpecVersion,
        address _callReceiver,
        bytes calldata _callPayload,
        uint256 _gasLimit,
        //
        uint128 _deliveryAndDispatchFee
    ) internal view {
        // solidity call that will be executed on crab smart chain
        bytes memory tgtInput = abi.encodeWithSelector(
            this.execute.selector,
            _callReceiver,
            _callPayload
        );

        // transact dispatch call that will be executed on crab chain
        bytes memory tgtTransactCallEncoded = PalletEthereum
            .encodeMessageTransactCall(
                PalletEthereum.MessageTransactCall(
                    remoteMessageTransactCallIndex,
                    PalletEthereum.buildTransactionV2ForMessageTransact(
                        _gasLimit,
                        remoteEndpoint,
                        remoteSmartChainId,
                        tgtInput
                    )
                )
            );
        uint64 tgtTransactCallWeight = uint64(_gasLimit * remoteWeightPerGas);

        // send_message dispatch call that will be executed on crab parachain
        bytes memory routerSendMessageCallEncoded = PalletBridgeMessages
            .encodeSendMessageCall(
                PalletBridgeMessages.SendMessageCall(
                    routerSendMessageCallIndex,
                    routerOutboundLaneId,
                    SmartChainXLib.buildMessage(
                        _tgtSpecVersion,
                        tgtTransactCallWeight,
                        tgtTransactCallEncoded
                    ),
                    _deliveryAndDispatchFee
                )
            );

        uint64 routerSendMessageCallWeight = uint64(
            1495248832 + 1351 * routerSendMessageCallEncoded.length
        ); // 1492481100 + (1 + message_size / 1024 + 1) * 1383866;

        // remote call send_message from moonbeam
        bytes[] memory interior = new bytes[](1);
        interior[0] = routerParachainId;
        IXcmTransactorV1.Multilocation memory dest = IXcmTransactorV1
            .Multilocation(1, interior);
        XcmTransactorV1.transactThroughSigned(
            dest,
            feeLocationAddress,
            routerSendMessageCallWeight,
            routerSendMessageCallEncoded
        );
    }

    ///////////////////////////////
    // Inbound
    ///////////////////////////////
    modifier onlyMessageSender() {
        require(
            derivedMessageSender == msg.sender,
            "MessageEndpoint: Invalid sender"
        );
        _;
    }

    function execute(address callReceiver, bytes calldata callPayload)
        external
        onlyMessageSender
    {
        if (_executable(callReceiver, callPayload)) {
            (bool success, ) = callReceiver.call(callPayload);
            require(success, "MessageEndpoint: Call execution failed");
        } else {
            revert("MessageEndpoint: Unapproved call");
        }
    }

    // Check if the call can be executed
    function _executable(address callReceiver, bytes calldata callPayload)
        internal
        view
        virtual
        returns (bool);

    ///////////////////////////////
    // Setters
    ///////////////////////////////
    function _setRemoteEndpoint(
        bytes4 _remoteChainId,
        bytes memory _parachainId,
        address _remoteEndpoint
    ) internal {
        remoteEndpoint = _remoteEndpoint;
        derivedMessageSender = SmartChainXLib
            .deriveSenderFromSmartChainOnMoonbeam(
                _remoteChainId,
                _remoteEndpoint,
                _parachainId
            );
    }

    function _setRemoteMessageTransactCallIndex(
        bytes2 _remoteMessageTransactCallIndex
    ) internal {
        remoteMessageTransactCallIndex = _remoteMessageTransactCallIndex;
    }

    function _setRemoteSmartChainId(uint64 _remoteSmartChainId) internal {
        remoteSmartChainId = _remoteSmartChainId;
    }

    function _setRemoteWeightPerGas(uint64 _remoteWeightPerGas) internal {
        remoteWeightPerGas = _remoteWeightPerGas;
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
