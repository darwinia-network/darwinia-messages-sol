// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../interfaces/IFeeMarket.sol";

contract MockFeeMarket is IFeeMarket {
    function market_fee() external pure override returns (uint256 fee) {
        return 1 ether;
    }

    function assign(uint256) external payable override returns(bool) {
        return true;
    }
    function settle(DeliveredRelayer[] calldata, address) external pure override returns(bool) {
        return true;
    }
}
