// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/ICrossChainFilter.sol";

contract NormalApp is ICrossChainFilter {

    receive() external payable {}

    fallback() external payable {}

    function crossChainFilter(uint32, uint32, address, bytes calldata) override external pure returns (bool) {
        return true;
    }
}
