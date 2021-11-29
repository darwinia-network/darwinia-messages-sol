// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IFeeMarket {
    function market_fee() external view returns (uint256 fee);
}
