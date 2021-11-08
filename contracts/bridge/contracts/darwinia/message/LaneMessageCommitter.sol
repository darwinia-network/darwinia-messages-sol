// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "../../interfaces/IMessageCommitment.sol";
import "../../common/message/LaneDataScheme.sol";

contract LaneMessageCommitter is Ownable, LaneDataScheme {
    event Registry(address inboundLane, address outboundLane);

    uint256 public immutable chainPosition;
    uint256 public laneCount;
    // bytes32 public laneMessageCommitmentRoot;
    mapping(uint256 => address) public inboundLanes;
    mapping(uint256 => address) public outboundLanes;

    constructor(uint256 _chainPosition) public {
        chainPosition = _chainPosition;
    }

    function registry(address inboundLane, address outboundLane) external onlyOwner {
        require(chainPosition == IMessageCommitment(inboundLane).chainPosition(), "Message: invalid chain position");
        require(chainPosition == IMessageCommitment(outboundLane).chainPosition(), "Message: invalid chain position");
        require(laneCount == IMessageCommitment(inboundLane).lanePosition(), "Message: invalid inlane position");
        require(laneCount == IMessageCommitment(outboundLane).lanePosition(), "Message: invalid outlane position");
        inboundLanes[laneCount] = inboundLane;
        outboundLanes[laneCount] = outboundLane;
        laneCount++;
        emit Registry(inboundLane, outboundLane);
    }

    // function commit() external returns (bytes32) {
    //     laneMessageCommitmentRoot = commitment();
    //     return laneMessageCommitmentRoot;
    // }

    function commitment(uint256 pos) public view returns (bytes32) {
        require(pos < laneCount, "Message: invalid position");
        address outbound_lane = outboundLanes[pos];
        address inbound_lane = inboundLanes[pos];
        LaneData memory lane_data = LaneData(
            IMessageCommitment(outbound_lane).commitment(),
            IMessageCommitment(inbound_lane).commitment()
        );
        return hash(lane_data);
    }

    // we use sparse tree to commit
    function commitment() public view returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](roundUpToPow2(laneCount));
        for (uint256 pos = 0; pos < laneCount; pos++) {
            hashes[pos] = commitment(pos);
        }
        uint256 hashLength = hashes.length;
        for (uint256 j = 0; hashLength > 1; j = 0) {
            for (uint256 i = 0; i < hashLength; i = i + 2) {
                hashes[j] = keccak256(abi.encodePacked(hashes[i], hashes[i + 1]));
                j = j + 1;
            }
            hashLength = hashLength - j;
        }
        return hashes[0];
    }

    // --- Math ---
    function roundUpToPow2(uint256 len) internal pure returns (uint256) {
        if (len <= 1) return 1;
        else return 2 * roundUpToPow2((len + 1) / 2);
    }
}
