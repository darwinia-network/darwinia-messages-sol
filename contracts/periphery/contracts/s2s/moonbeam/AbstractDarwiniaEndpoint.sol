// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../RemoteDispatchEndpoint.sol";
import "../SmartChainXLib.sol";
import "../types/PalletMessageRouter.sol";
import "../types/PalletEthereumXcm.sol";

abstract contract AbstractDarwiniaEndpoint is RemoteDispatchEndpoint {
    // Target params
    address public remoteEndpoint;
    bytes2 public remoteMessageTransactCallIndex;
    address public derivedMessageSender; // message sender derived from remoteEndpoint

    // router params
    bytes2 public routerForwardCallIndex;
    uint64 public routerForwardCallWeight = 337_239_000;

    event TargetInputGenerated(bytes);
    event TargetTransactCallGenerated(bytes);

    ///////////////////////////////
    // Outbound
    ///////////////////////////////
    function _remoteExecute(
        uint32 _routerSpecVersion,
        address _callReceiver,
        bytes calldata _callPayload,
        uint256 _gasLimit
    ) internal returns (uint256) {
        bytes memory input = abi.encodeWithSelector(
            this.execute.selector,
            _callReceiver,
            _callPayload
        );

        emit TargetInputGenerated(input);

        // build the TransactCall
        bytes memory tgtTransactCallEncoded = PalletEthereumXcm
            .buildTransactCall(
                remoteMessageTransactCallIndex,
                _gasLimit,
                remoteEndpoint,
                0,
                input
            );

        emit TargetTransactCallGenerated(tgtTransactCallEncoded);

        // build the ForwardCall
        bytes memory routerForwardCallEncoded = PalletMessageRouter
            .buildForwardCall(
                routerForwardCallIndex,
                tgtTransactCallEncoded,
                0 // moonbeam
            );

        // dispatch the ForwardCall
        return
            _remoteDispatch(
                _routerSpecVersion,
                routerForwardCallEncoded,
                routerForwardCallWeight
            );
    }
        );

        return encodeMessageId(outboundLaneId, messageNonce);
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
}
