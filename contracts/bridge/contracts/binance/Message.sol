// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "./LaneDataScheme.sol";

contract Message is Ownable, LaneDataScheme {
    event RegistryLane(address inboundLane, address outboundLane);

    uint256 public laneCount;
    mapping(uint256 => address) inboundLanes;
    mapping(uint256 => address) outboundLanes;

    function registry(address inboundLane, address outboundLane) external onlyOwner {
        // require(laneCount == IMessageCommitment(inboundLane).lanePosition(), "Message: invalid inlane index");
        // require(laneCount == IMessageCommitment(outboundLane).lanePosition(), "Message: invalid outlane index");
        inboundLanes[laneCount] = inboundLane;
        outboundLanes[laneCount] = outboundLane;
        laneCount++;
        emit RegistryLane(inboundLane, outboundLane);
    }

    // function commitment(uint256 pos) public view returns (bytes32) {
        
    // }

    // function commitment() external view {
    //     for (uint256 pos = 0; pos < laneCount; pos++) {
    //         commitment(pos);
    //     }
    // }
}
