// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "../darwinia/MappingTokenAddress.sol";

contract MockDispatchCall is MappingTokenAddress {
    uint64 public generated_nonce = 0;
    uint256 minFee = 50 ether;
    function send_message(uint32 pallet_id, bytes4 lane_id, bytes memory message, uint256 fee) external {
        generated_nonce += 1;
        require(minFee <= fee, "fee is too small");
        require(pallet_id == 43, "invalid palletid");
        require(lane_id == 0x726f6c69, "invalid laneid");
        require(message.length > 0, "invalid message");
    }
}

