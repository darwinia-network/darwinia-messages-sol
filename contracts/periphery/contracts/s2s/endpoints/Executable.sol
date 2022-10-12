// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// A dapp can be executed by a inbound message.
// `execute` function will be invoked by the message.
abstract contract Executable {
    address public derivedMessageSender; // message sender derived from remoteEndpoint

    modifier onlyMessageSender() {
        require(
            derivedMessageSender == msg.sender,
            "MessageEndpoint: Invalid sender"
        );
        _;
    }

    function execute(address callReceiver, bytes calldata callPayload)
        external
        onlyMessageSender
    {
        if (_allowed(callReceiver, callPayload)) {
            (bool success, ) = callReceiver.call(callPayload);
            require(success, "MessageEndpoint: Call execution failed");
        } else {
            revert("MessageEndpoint: Unapproved call");
        }
    }

    // Check if the call can be executed
    function _allowed(address callReceiver, bytes calldata callPayload)
        internal
        view
        virtual
        returns (bool);
}
