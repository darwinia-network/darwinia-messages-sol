// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./RelayAuthorities.sol";

contract POSALightClient is RelayAuthorities {

    contructor(
        bytes32 _network,
        address[] memory _relayers,
        uint256 _threshold
    ) RelayAuthorities(_network, _relayers, _threshold) {}
}
