// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../endpoints/routing/moonbeam/AbstractMoonbeamEndpoint.sol";

contract MoonbaseEndpoint is AbstractMoonbeamEndpoint {
    constructor() {
        targetSmartChainId = 43;
        targetMessageTransactCallIndex = 0x2901;
        routerSendMessageCallIndex = 0x1503;
        routerOutboundLaneId = 0x70616c69; // pali
        routerParachainId = 0x00000839;
        feeLocationAddress = 0xFFFffFfF8283448b3cB519Ca4732F2ddDC6A6165;
    }

    function _allowed(address, bytes calldata)
        internal
        pure
        override
        returns (bool)
    {
        return true;
    }

    function targetExecute(
        uint32 _tgtSpecVersion,
        address _callReceiver,
        bytes calldata _callPayload,
        uint256 _gasLimit,
        uint128 _deliveryAndDispatchFee
    ) external payable {
        _targetExecute(
            _tgtSpecVersion,
            _callReceiver,
            _callPayload,
            _gasLimit,
            _deliveryAndDispatchFee
        );
    }

    function setTargetEndpoint(
        bytes4 _targetChainId,
        bytes4 _parachainId,
        address _targetEndpoint
    ) external
    {
        _setTargetEndpoint(_targetChainId, _parachainId, _targetEndpoint);
    }
}
