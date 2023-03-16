// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IOutboundLane.sol";
import "../interfaces/IFeeMarket.sol";

contract EthereumEndpoint {
    address public constant OUTBOUND_LANE = 0x5a10ca57e07133AA5132eF29BA1EBf0096a302B0;
    address public constant FEE_MARKET = 0xA10D0C6e04845A5e998d1936249A30563c553417;

    address public constant DARWINIA_ENDPOINT = 0x5a10ca57e07133AA5132eF29BA1EBf0096a302B0;

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
    ) payable external returns (uint64 nonce) {
        return executeOnDarwinia(
            abi.encodeWithSignature(
                "dispatchOnParachain(bytes2,bytes,uint64)", 
                paraId,
                paraCall,
                weight
            )
        );
    }

    // Ethereum > Darwinia 
    function executeOnDarwinia(bytes memory call) payable public returns (uint64 nonce) {
        return IOutboundLane(OUTBOUND_LANE).send_message{value: IFeeMarket(FEE_MARKET).market_fee()}(
            DARWINIA_ENDPOINT,
            call 
        );
    }
}
