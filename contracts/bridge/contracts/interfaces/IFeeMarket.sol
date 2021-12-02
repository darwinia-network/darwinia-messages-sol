// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IFeeMarket {
    struct DeliveredRelayer {
        address relayer;
        uint256 begin;
        uint256 end;
    }
    function market_fee() external view returns (uint256 fee);

    function assign(uint256 nonce) external payable returns(bool);
    function settle(DeliveredRelayer[] calldata delivery_relayers, address confirm_relayer) external returns(bool);
}
