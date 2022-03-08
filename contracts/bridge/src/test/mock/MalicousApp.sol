// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/ICrossChainFilter.sol";
import "../../interfaces/IOnMessageDelivered.sol";
import "../../interfaces/IOutboundLane.sol";

contract MalicousApp is ICrossChainFilter, IOnMessageDelivered {

    function crossChainFilter(uint32, uint32, address, bytes calldata) external override pure returns (bool) {
        return true;
    }

    function malicious(address outlane, bytes memory large) public payable {
        bytes memory encoded = abi.encode(this.loop.selector, large);
        IOutboundLane(outlane).send_message{value: msg.value}(address(this), encoded);
    }

    function on_messages_delivered(uint256, bool) external pure override {
        loop("");
    }

    function loop(bytes memory) public pure {
        uint cnt;
        while(true) {
            cnt++;
        }
    }
}
