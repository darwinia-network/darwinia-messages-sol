// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title A interface for app layer to get message dispatch result
 * @author echo
 * @notice The app layer could implement the interface `IOnMessageDelivered` to receive message dispatch result (optionally)
 */
interface IOnMessageDelivered {
    /**
     * @notice Message delivered callback
     * @param nonce Nonce of the callback message
     * @param dispatch_result Dispatch result of cross chain message
     */
    function onMessagesDelivered(uint64 nonce, bool dispatch_result) external;
}
