// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../../interfaces/ICrossChainFilter.sol";
import "../../interfaces/IOutboundLane.sol";

contract MalicousApp is ICrossChainFilter {

    function cross_chain_filter(uint32, uint32, address, bytes calldata) external override pure returns (bool) {
        return true;
    }

    function malicious(address outlane, bytes memory large) public payable {
        bytes memory encoded = abi.encode(this.loop.selector, large);
        IOutboundLane(outlane).send_message{value: msg.value}(address(this), encoded);
    }

    function loop(bytes memory) public pure {
        uint cnt;
        while(true) {
            cnt++;
        }
    }
}
