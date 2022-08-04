// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/Math.sol";
import "../../interfaces/IMessageCommitment.sol";

/// @title LaneMessageCommitter
/// @author echo
/// @notice Lane message committer commit all messages from this chain to bridged chain
/// @dev Lane message use sparse merkle tree to commit all messages
contract LaneMessageCommitter is Math {
    event Registry(uint256 outLanePos, address outboundLane, uint256 inLanePos, address inboundLane);
    event ChangeLane(uint256 pos, address lane);

    /// @dev This chain position
    uint256 public immutable thisChainPosition;
    /// @dev Bridged chain position
    uint256 public immutable bridgedChainPosition;
    /// @dev Count of all lanes in committer
    uint256 public count;
    /// @dev Lane positon => lane address
    mapping(uint256 => address) public laneOf;
    /// @dev Governance role to set lanes config
    address public setter;

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    /// @dev Constructor params
    /// @param _thisChainPosition This chain positon
    /// @param _bridgedChainPosition Bridged chain positon
    constructor(uint256 _thisChainPosition, uint256 _bridgedChainPosition) {
        require(_thisChainPosition != _bridgedChainPosition, "!pos");
        thisChainPosition = _thisChainPosition;
        bridgedChainPosition = _bridgedChainPosition;
        setter = msg.sender;
    }

    /// @dev Change the setter
    /// @notice Only could be called by setter
    /// @param _setter The new setter
    function changeSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    /// @dev Change lane address of the given positon
    /// @notice Only could be called by setter
    /// @param pos The given positon
    /// @param lane New lane address of the given positon
    function changeLane(uint256 pos, address lane) external onlySetter {
        require(laneOf[pos] != address(0), "!exist");
        (uint32 _thisChainPosition, uint32 _thisLanePosition, uint32 _bridgedChainPosition, ) = IMessageCommitment(lane).getLaneInfo();
        require(thisChainPosition == _thisChainPosition, "!thisChainPosition");
        require(bridgedChainPosition == _bridgedChainPosition, "!bridgedChainPosition");
        require(pos == _thisLanePosition, "!thisLanePosition");
        laneOf[pos] = lane;
        emit ChangeLane(pos, lane);
    }

    /// @dev Registry a pair of out lane and in lane
    /// @notice Only could be called by setter
    /// @param outboundLane Address of outbound lane
    /// @param inboundLane Address of inbound lane
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

    /// @dev Get the commitment of a lane
    /// @notice Return bytes(0) if the lane address is address(0)
    /// @param lanePos Positon of the lane
    /// @return Commitment of the lane
    function commitment(uint256 lanePos) public view returns (bytes32) {
        address lane = laneOf[lanePos];
        if (lane == address(0)) {
            return bytes32(0);
        } else {
            return IMessageCommitment(lane).commitment();
        }
    }

    /// @dev Get the commitment of all lanes in this committer
    /// @notice Return bytes(0) if there is no lane
    /// @return Commitment of this committer
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
