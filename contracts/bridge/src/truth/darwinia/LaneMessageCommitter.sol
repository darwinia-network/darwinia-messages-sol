// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/Math.sol";
import "../../interfaces/IMessageCommitment.sol";

/// @title LaneMessageCommitter
/// @notice Lane message committer commit all messages from this chain to bridged chain
/// @dev Lane message use sparse merkle tree to commit all messages
contract LaneMessageCommitter is Math {
    event Registry(uint256 outLanePos, address outboundLane, uint256 inLanePos, address inboundLane);
    event ChangeLane(uint256 pos, address lane);

    /// @dev This chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
    uint256 public immutable thisChainPosition;
    /// @dev Bridged chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
    uint256 public immutable bridgedChainPosition;
    /// @dev Count of all lanes in committer
    uint256 public count;
    /// lane positon => lane address
    mapping(uint256 => address) public laneOf;
    /// Governance role to registry new lane
    address public setter;

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    constructor(uint256 _thisChainPosition, uint256 _bridgedChainPosition) {
        require(_thisChainPosition != _bridgedChainPosition, "!pos");
        thisChainPosition = _thisChainPosition;
        bridgedChainPosition = _bridgedChainPosition;
        setter = msg.sender;
    }

    function changeSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    function changeLane(uint256 pos, address lane) external onlySetter {
        require(laneOf[pos] != address(0), "!exist");
        (uint32 _thisChainPosition, uint32 _thisLanePosition, uint32 _bridgedChainPosition, ) = IMessageCommitment(lane).getLaneInfo();
        require(thisChainPosition == _thisChainPosition, "!thisChainPosition");
        require(bridgedChainPosition == _bridgedChainPosition, "!bridgedChainPosition");
        require(pos == _thisLanePosition, "!thisLanePosition");
        laneOf[pos] = lane;
        emit ChangeLane(pos, lane);
    }

    function registry(address outboundLane, address inboundLane) external onlySetter {
        (uint32 _thisChainPositionOut, uint32 _thisLanePositionOut, uint32 _bridgedChainPositionOut, ) = IMessageCommitment(outboundLane).getLaneInfo();
        (uint32 _thisChainPositionIn, uint32 _thisLanePositionIn, uint32 _bridgedChainPositionIn, ) = IMessageCommitment(inboundLane).getLaneInfo();
        require(thisChainPosition == _thisChainPositionOut, "!thisChainPosition");
        require(thisChainPosition == _thisChainPositionIn, "!thisChainPosition");
        require(bridgedChainPosition == _bridgedChainPositionOut, "!bridgedChainPosition");
        require(bridgedChainPosition == _bridgedChainPositionIn, "!bridgedChainPosition");
        uint256 outLanePos = count;
        uint256 inLanePos = count + 1;
        require(outLanePos == _thisLanePositionOut, "!thisLanePosition");
        require(inLanePos == _thisLanePositionIn, "!thisLanePosition");
        laneOf[outLanePos] = outboundLane;
        laneOf[inLanePos] = inboundLane;
        count += 2;
        emit Registry(outLanePos, outboundLane, inLanePos, inboundLane);
    }

    function commitment(uint256 lanePos) public view returns (bytes32) {
        address lane = laneOf[lanePos];
        if (lane == address(0)) {
            return bytes32(0);
        } else {
            return IMessageCommitment(lane).commitment();
        }
    }

    // we use sparse tree to commit
    function commitment() public view returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](get_power_of_two_ceil(count));
        for (uint256 pos = 0; pos < count; pos++) {
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
}
