// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../darwinia/AbstractDarwiniaEndpoint.sol";
import "../interfaces/ICrossChainFilter.sol";

contract Pangolin2Endpoint is
    AbstractDarwiniaEndpoint(
        0x2100,
        0xe520,
        0xd3686C9a2Ff3Fa3dc24E2ab157f58B2d567A295e,
        0xE233a0E201219f792B878517e840903B8d62B9d3
    )
{
    function cross_chain_filter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata payload
    ) external view returns (bool) {
        return true;
    }
}
