// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @dev This is the interface of substrate<>substrate bridge precompile contract through which solidity contracts
 * will interact with Substrate To Substrate Bridge. 
 * 
 * TIP: We use read only function to avoid update state by these interface. Users who want to update state can get
 * the encoded dispatch call value and then use the dispatch precompile to execute a dispatch call
 * 
 * @author Darwinia Network Team
 */
interface SubToSubBridge {
    /// @dev get the sub<>sub outbound latest generated message id, this id combined by laneid and nonce. It's also
    /// the last sent message's id.
    /// @param laneid The lane id in which message sent. Use this params to distinguish different channel.
    function outbound_latest_generated_nonce(bytes4 laneid) external view returns (uint64);

    /// @dev get the sub<>sub inbound latest received message id, this id combined by laneid and nonce.
    /// #param laneid The land id in which message sent.
    function inbound_latest_received_nonce(bytes4 laneid) external view returns (uint64);

    /// #dev get the scale encoded payload of the `unlock_from_remote` dispatch call which defined in s2s/issuing pallet
    /// this payload satisfy the standard format of the sub<>sub message payload
    /// @param spec_version the spec_version of the remote chain
    /// @param weight the remote dispatch call's weight, here is `unlock_from_remote`'s weight
    /// @param token_type the token type of the original token, Native/Erc20 or others
    /// @param original_token the address of the original token
    /// @param recipient the reciver of the remote unlock token
    /// @param amount of the original token unlocked
    function encode_unlock_from_remote_dispatch_call(
        uint32 spec_version,
        uint64 weight,
        uint32 token_type,
        address original_token,
        bytes memory recipient,
        uint256 amount) external view returns(bytes memory);

    /// @dev get the scale encoded stream of the sub<>sub send message dispatch call. then you can use dispatch precompile to
    /// call it to send sub<>sub message
    /// @param msg_pallet_id the sub<>sub message bridge pallet index
    /// @param lane_id the bridge's lane id
    /// @param message the payload of the message
    /// @param fee the fee of the bridge, we can get this value from fee market
    function encode_send_message_dispatch_call(uint32 msg_pallet_id, bytes4 lane_id, bytes memory message, uint256 fee) external view returns(bytes memory);

    /// @dev get the scale encoded stream of the `register_from_remote` dispatch call which defined in s2s/issuing pallet
    /// @param spec_version the spec_version of the remote chain
    /// @param weight the remote dispatch call's weight, here is `unlock_from_remote`'s weight
    /// @param token_type the token type of the original token, Native/Erc20 or others
    /// @param token the original token address
    /// @param name the name of the original token
    /// @param symbol the symbol of the original token
    /// @param decimals the decimals of the original token
    function encode_register_from_remote_dispatch_call(
        uint32 spec_version,
        uint64 weight,
        uint32 token_type,
        address token,
        string memory name,
        string memory symbol,
        uint8 decimals) external view returns(bytes memory);

    /// @dev get the scale encoded stream of the `issue_from_remote` dispatch call which defined in s2s/issuing pallet
    /// @param spec_version the spec_version of the remote chain
    /// @param weight the remote dispatch call's weight, here is `unlock_from_remote`'s weight
    /// @param token the original token address
    /// @param recipient the receiver of the mapped token issued
    /// @param amount the amount of the mapped token issued
    function encode_issue_from_remote_dispatch_call(
        uint32 spec_version,
        uint64 weight,
        address token,
        address recipient,
        uint256 amount
    ) external view returns(bytes memory);
}

