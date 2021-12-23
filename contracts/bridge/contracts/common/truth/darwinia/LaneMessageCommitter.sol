// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../../../interfaces/IMessageCommitment.sol";

contract LaneMessageCommitter {
    event Registry(uint256 outLanePos, address outboundLane, uint256 inLanePos, address inboundLane);

    uint256 public immutable thisChainPosition;
    uint256 public immutable bridgedChainPosition;
    uint256 public laneCount;
    mapping(uint256 => address) public lanes;

    address public setter;

    modifier onlySetter {
        require(msg.sender == setter, "Commit: forbidden");
        _;
    }

    constructor(uint256 _thisChainPosition, uint256 _bridgedChainPosition) public {
        require(_thisChainPosition != _bridgedChainPosition, "Commit: invalid position");
        thisChainPosition = _thisChainPosition;
        bridgedChainPosition = _bridgedChainPosition;
        setter = msg.sender;
    }

    function changeSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    function registry(address outboundLane, address inboundLane) external onlySetter {
        require(thisChainPosition == IMessageCommitment(outboundLane).thisChainPosition(), "Commit: invalid ThisChainPosition");
        require(thisChainPosition == IMessageCommitment(inboundLane).thisChainPosition(), "Commit: invalid ThisChainPosition");
        require(bridgedChainPosition == IMessageCommitment(outboundLane).bridgedChainPosition(), "Commit: invalid chain position");
        require(bridgedChainPosition == IMessageCommitment(inboundLane).bridgedChainPosition(), "Commit: invalid chain position");
        uint256 outLanePos = laneCount;
        uint256 inLanePos = laneCount + 1;
        require(outLanePos == IMessageCommitment(outboundLane).thisLanePosition(), "Commit: invalid outlane position");
        require(inLanePos == IMessageCommitment(inboundLane).thisLanePosition(), "Commit: invalid inlane position");
        lanes[outLanePos] = outboundLane;
        lanes[inLanePos] = inboundLane;
        laneCount += 2;
        emit Registry(outLanePos, outboundLane, inLanePos, inboundLane);
    }

    function commitment(uint256 lanePos) public view returns (bytes32) {
        address lane = lanes[lanePos];
        if (lane == address(0)) {
            return bytes32(0);
        } else {
            return IMessageCommitment(lane).commitment();
        }
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
