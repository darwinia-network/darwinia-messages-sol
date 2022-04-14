// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../../interfaces/ICrossChainFilter.sol";
import "../../interfaces/IOnMessageDelivered.sol";
import "../../interfaces/IOutboundLane.sol";

contract NormalApp is ICrossChainFilter, IOnMessageDelivered {

    IOutboundLane outlane;

    constructor(address _outlane) {
        outlane = IOutboundLane(_outlane);
    }

    receive() external payable {}

    fallback() external payable {}

    function crossChainFilter(uint32, uint32, address, bytes calldata) external pure override returns (bool) {
        return true;
    }

    function on_messages_delivered(uint256, bool) external pure override {
        return;
    }

    function send_message(address target, bytes calldata encoded) external payable returns (uint256) {
        return outlane.send_message{value: msg.value}(target, encoded);
    }
}
