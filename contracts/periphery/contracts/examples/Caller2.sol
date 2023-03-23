// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GoerliEndpoint.sol";

// Goerli(transaction fee + market fee)
// Caller2 > GoerliEndpoint -- relayer --> PangolinDevEndpoint > polkadotXcm.send > --> astar
//
// `EndUser` call `Dapp`, then `Dapp` use messaging service to call
//
// Payment flow on Goerli:
//
//   ENDUSER pay to DAPP,                        <--- Dapp
//      then DAPP pay to ENDPOINT,               <--- Dapp Endpoint
//        then ENDPOINT pay to OUTBOUNDLANE,     <--- Message Layer
//          then OUTBOUNDLANE pay to RELAYER     <--- Message Layer
//
//   ENDUSER depoist XCM Execute Fee himself manually on Parachain.
contract Caller2 {
    address public endpointAddress;

    constructor(address _endpointAddress) {
        endpointAddress = _endpointAddress;
    }

    function remoteAdd(
        bytes2 paraId,
        bytes memory paraCall,
        uint64 weight,
        uint128 fungible
    ) external payable returns (uint64 nonce) {
        nonce = GoerliEndpoint(endpointAddress).xcmTransactOnParachain{
            value: msg.value
        }(paraId, paraCall, weight, fungible);
    }
}
