// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IOutboundLane.sol";
import "../interfaces/IFeeMarket.sol";
import "../interfaces/ICrossChainFilter.sol";

abstract contract AbstractEthereumEndpoint is ICrossChainFilter {
    address public immutable TO_DARWINIA_OUTBOUND_LANE;
    address public immutable TO_DARWINIA_FEE_MARKET;
    address public darwiniaEndpoint;

    constructor(address _toDarwiniaOutboundLane, address _toDarwiniaFeeMarket) {
        TO_DARWINIA_OUTBOUND_LANE = _toDarwiniaOutboundLane;
        TO_DARWINIA_FEE_MARKET = _toDarwiniaFeeMarket;
    }

    // A helper function to call a dispatch_call on ethereum
    // ethereum > darwinia > parachain
    //
    // Payment flow on ethereum:
    //   ENDUSER pay to DAPP,
    //      then DAPP pay to ENDPOINT,
    //        then ENDPOINT pay to OUTBOUNDLANE,
    //          then OUTBOUNDLANE pay to RELAYER
    function dispatchOnParachain(
        bytes2 paraId,
        bytes memory paraCall,
        uint64 weight
    ) external payable returns (uint64 nonce) {
        return
            remoteExecute(
                abi.encodeWithSignature(
                    "dispatchOnParachain(bytes2,bytes,uint64)",
                    paraId,
                    paraCall,
                    weight
                )
            );
    }

    // Execute a darwinia endpoint function.
    // ethereum > darwinia
    function remoteExecute(
        bytes memory call
    ) public payable returns (uint64 nonce) {
        return
            IOutboundLane(TO_DARWINIA_OUTBOUND_LANE).send_message{
                value: IFeeMarket(TO_DARWINIA_FEE_MARKET).market_fee()
            }(darwiniaEndpoint, call);
    }

    function _setDarwiniaEndpoint(address _darwiniaEndpoint) internal {
        darwiniaEndpoint = _darwiniaEndpoint;
    }
}
