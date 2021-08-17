// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IOutboundChannel.sol";

// BasicOutboundChannel is a basic channel that just sends messages with a nonce.
contract BasicOutboundChannel is IOutboundChannel, AccessControl {

    bytes32 public constant OUTBOUND_ROLE = keccak256("OUTBOUND_ROLE");

    uint256 public nonce;

    event Message(
        address source,
        uint256 nonce,
        bytes payload
    );

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Sends a message across the channel
     */
    function submit(bytes calldata payload) external override {
        require(hasRole(OUTBOUND_ROLE, msg.sender), "Channel: not-authorized");
        nonce = nonce + 1;
        emit Message(msg.sender, nonce, payload);
    }
}
