// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "../interfaces/ICrossChainFilter.sol";

contract MalicousApp is ICrossChainFilter {

    function crossChainFilter(uint32, uint32, address, bytes calldata) external override view returns (bool) {
        return true;
    }

    function loop(bytes calldata) external pure {
        uint cnt;
        while(true) {
            cnt++;
        }
    }
}
