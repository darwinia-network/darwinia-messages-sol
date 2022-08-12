// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/Math.sol";
import "../common/MessageCommitter.sol";
import "../../interfaces/IMessageCommitment.sol";

/// @title LaneMessageCommitter
/// @author echo
/// @notice Lane message committer commit all messages from this chain to bridged chain
/// @dev Lane message use sparse merkle tree to commit all messages
contract LaneMessageCommitter is Math, MessageCommitter {
    event Registry(uint256 outLanePos, address outboundLane, uint256 inLanePos, address inboundLane);
    event ChangeLane(uint256 pos, address lane);

    /// @dev This chain position
    uint256 public immutable thisChainPosition;
    /// @dev Bridged chain position
    uint256 public immutable bridgedChainPosition;
    /// @dev Count of all lanes in committer
    uint256 public laneCount;
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

    function count() public view override returns (uint256) {
        return laneCount;
    }

    function leaveOf(uint256 pos) public view override returns (address) {
        return laneOf[pos];
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
        uint256 outLanePos = laneCount;
        uint256 inLanePos = laneCount + 1;
        require(outLanePos == _thisLanePositionOut, "!thisLanePosition");
        require(inLanePos == _thisLanePositionIn, "!thisLanePosition");
        laneOf[outLanePos] = outboundLane;
        laneOf[inLanePos] = inboundLane;
        laneCount += 2;
        emit Registry(outLanePos, outboundLane, inLanePos, inboundLane);
    }
}
