// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../darwinia/AbstractDarwiniaEndpoint.sol";
import "../interfaces/ICrossChainFilter.sol";

contract Pangolin2Endpoint is
    AbstractDarwiniaEndpoint(
        0x2100,
        0xe520,
        0xbA6c0608f68fA12600382Cd4D964DF9f090AA5B5,
        0x3553b673A47E66482b6eCFAE5bfc090Cc7eeEd27
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
