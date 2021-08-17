// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

interface ICrossChainFilter {
    function crossChainFilter(address sourceAccount, bytes calldata payload) external view returns (bool); 
}
