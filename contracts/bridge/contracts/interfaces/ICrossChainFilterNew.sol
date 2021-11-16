// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

/**
 * @title A interface for message layer to filter unsafe message
 * @author echo
 * @notice The app layer must implement the interface `ICrossChainFilter`
 */
interface ICrossChainFilter {
    /**
     * @notice Verify the source sender and payload of source chain messages,
     * Generally, app layer cross-chain messages require validation of sourceAccount
     * @param sourceChainPosition The source chain position which send the message
     * @param sourceAccount The source contract address which send the message
     * @param payload The calldata which encoded by ABI Encoding
     * @return Can call target contract if returns true
     */
    function crossChainFilter(uint256 sourceChainPosition, address sourceAccount, bytes calldata payload) external view returns (bool);
}
