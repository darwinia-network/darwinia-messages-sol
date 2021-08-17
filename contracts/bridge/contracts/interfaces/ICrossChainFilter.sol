// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

interface ICrossChainFilter {
    function filter(address src, address dst, bytes4 sig) external view returns (bool); 
}
