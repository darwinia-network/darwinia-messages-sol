// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "../interfaces/ICrossChainFilter.sol";

contract DemoApp is ICrossChainFilter {

    function crossChainFilter(address sourceAccount, bytes memory) public override view returns (bool) {
        require(sourceAccount == address(0), "invalid source account");
        return true;
    }
}
