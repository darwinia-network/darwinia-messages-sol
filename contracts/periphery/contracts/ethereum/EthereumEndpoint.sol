// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IOutboundLane.sol";

contract EthereumEndpoint {
    address public constant OUTBOUND_LANE = 0x5a10ca57e07133AA5132eF29BA1EBf0096a302B0;
    address public constant DARWINIA_ENDPOINT = 0x5a10ca57e07133AA5132eF29BA1EBf0096a302B0;

    // dispatch `paraId`.`paraCall`
    function dispatchOnParachain(bytes2 paraId, bytes memory paraCall, uint64 weight) payable external {
        bytes memory darwiniaCall = abi.encodeWithSignature(
            "dispatchOnParachain(bytes2,bytes,uint64)", 
            paraId, 
            paraCall, 
            weight
        );

        IOutboundLane(OUTBOUND_LANE).send_message{value: msg.value}(
            // darwinia target contract.
            DARWINIA_ENDPOINT,
            // darwinia calldata to be executed.
            darwiniaCall
        );
    }

    /////////////////////////////////////////////
    // INTERNAL FUNCTIONS
    /////////////////////////////////////////////
}
