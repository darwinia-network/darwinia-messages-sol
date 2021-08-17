// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

interface ICrossChainFilter {
    function crossChainfilter(address sourceAccount, bytes memory payload) external view returns (bool); 
}
