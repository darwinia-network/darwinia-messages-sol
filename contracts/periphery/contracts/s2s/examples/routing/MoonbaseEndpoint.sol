// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../moonbeam/AbstractMoonbeamEndpoint.sol";

contract MoonbaseEndpoint is AbstractMoonbeamEndpoint {
    constructor() {
        remoteSmartChainId = 43;
        remoteMessageTransactCallIndex = 0x2901;
        routerSendMessageCallIndex = 0x1503;
        routerOutboundLaneId = 0x70616c69; // pali
        routerParachainId = hex"0839";
        feeLocationAddress = address(1024);
    }

    function _executable(address, bytes calldata)
        internal
        pure
        override
        returns (bool)
    {
        return true;
    }

    function remoteExecute(
        uint32 _tgtSpecVersion,
        address _callReceiver,
        bytes calldata _callPayload,
        uint256 _gasLimit,
        uint128 _deliveryAndDispatchFee
    ) external payable {
        _remoteExecute(
            _tgtSpecVersion,
            _callReceiver,
            _callPayload,
            _gasLimit,
            _deliveryAndDispatchFee
        );
    }
}
