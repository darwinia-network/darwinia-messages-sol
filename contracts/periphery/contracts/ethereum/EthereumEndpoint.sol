// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IOutboundLane.sol";
import "../interfaces/IFeeMarket.sol";

contract EthereumEndpoint {
    address public immutable TO_DARWINIA_OUTBOUND_LANE;
    address public immutable TO_DARWINIA_FEE_MARKET;
    address public immutable DARWINIA_ENDPOINT;

    constructor(
        address _toDarwiniaOutboundLane,
        address _toDarwiniaFeeMarket,
        address _darwiniaEndpoint
    ) {
        TO_DARWINIA_OUTBOUND_LANE = _toDarwiniaOutboundLane;
        TO_DARWINIA_FEE_MARKET = _toDarwiniaFeeMarket;
        DARWINIA_ENDPOINT = _darwiniaEndpoint;
    }

    // Ethereum > Darwinia > Parachain
    // dispatch a call on parachain
    //
    // On Ethereum:
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
            executeOnDarwinia(
                abi.encodeWithSignature(
                    "dispatchOnParachain(bytes2,bytes,uint64)",
                    paraId,
                    paraCall,
                    weight
                )
            );
    }

    // Ethereum > Darwinia
    function executeOnDarwinia(
        bytes memory call
    ) public payable returns (uint64 nonce) {
        return
            IOutboundLane(TO_DARWINIA_OUTBOUND_LANE).send_message{
                value: IFeeMarket(TO_DARWINIA_FEE_MARKET).market_fee()
            }(DARWINIA_ENDPOINT, call);
    }
}
