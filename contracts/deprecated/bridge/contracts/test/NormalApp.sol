// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "../interfaces/ICrossChainFilter.sol";

contract NormalApp is ICrossChainFilter {

    fallback() external {}

    function crossChainFilter(uint32, uint32, address, bytes calldata) override external view returns (bool) {
        return true;
    }
}
