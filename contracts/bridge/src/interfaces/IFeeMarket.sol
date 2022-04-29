// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma abicoder v2;

/// @title A interface for user to enroll to be a relayer.
/// @author echo
/// @notice After enroll to be a relyer , you have the duty to relay
/// the meesage which is assigned to you, or you will be slashed
interface IFeeMarket {
    //  Relayer which delivery the messages
    struct DeliveredRelayer {
        // relayer account
        address relayer;
        // encoded message key begin
        uint256 begin;
        // encoded message key end
        uint256 end;
    }
    /// @dev return the real time market maker fee
    /// @notice Revert `!top` when there is not enroll relayer in the fee-market
    function market_fee() external view returns (uint256 fee);
    // Assign new message encoded key to top N relayers in fee-market
    function assign(uint256 nonce) external payable returns(bool);
    // Settle delivered messages and reward/slash relayers
    function settle(DeliveredRelayer[] calldata delivery_relayers, address confirm_relayer) external returns(bool);
}
