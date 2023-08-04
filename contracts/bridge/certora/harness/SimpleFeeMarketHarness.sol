// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../munged/SimpleFeeMarket.f.sol";

contract SimpleFeeMarketHarness is SimpleFeeMarket {

    constructor(
        uint256 _collateral_perorder,
        uint256 _slash_time,
        uint256 _relay_time,
        uint256 _price_ratio_numerator,
        uint256 _duty_reward_ratio
    ) SimpleFeeMarket(
        _collateral_perorder,
        _slash_time,
        _relay_time,
        _price_ratio_numerator,
        _duty_reward_ratio
    ) {
        initialize();
    }
}
