// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IFeeMarket {
    function market_fee() external view returns (uint256 fee);

    function assign(uint64 nonce) external payable returns(bool);
    function delivery(uint64 begin, uint256 end) external returns(bool);
}
