// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IOutboundLane.sol";

contract EthereumEndpoint {
    /* address public constant OUTBOUND_LANE = 0x5a10ca57e07133AA5132eF29BA1EBf0096a302B0; */

    // FakeOutboundLane
    address public constant OUTBOUND_LANE = 0x80F262b37544339825974A6dB8B7b6e0ff861FAF;
    address public constant DARWINIA_ENDPOINT = 0x5a10ca57e07133AA5132eF29BA1EBf0096a302B0;

    // execute `target`.`call` on astar.
    function executeOnAstar(address target, bytes memory call) payable external {
        executeOnDarwinia(
            // darwinia target contract.
            DARWINIA_ENDPOINT,
            // darwinia calldata to be executed.
            buildCallOfDarwinia(target, call)
        );
    }

    /////////////////////////////////////////////
    // INTERNAL FUNCTIONS
    /////////////////////////////////////////////
    function buildCallOfDarwinia(address target, bytes memory callOfAstar) internal pure returns (bytes memory){
        return abi.encodeWithSignature("executeOnAstar(address,bytes)", target, callOfAstar);
    }
    
    // execute `target`.`call` on darwinia.
    function executeOnDarwinia(address target, bytes memory call) internal returns (uint64) {
        return IOutboundLane(OUTBOUND_LANE).send_message{value: msg.value}(
            target,
            call
        );
    }
}
