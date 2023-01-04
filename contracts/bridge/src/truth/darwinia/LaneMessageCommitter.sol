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

pragma solidity 0.8.17;

import "../common/MessageCommitter.sol";
import "../../interfaces/ILane.sol";

/// @title LaneMessageCommitter
/// @notice Lane message committer commit all messages from this chain to bridged chain
/// @dev Lane message use sparse merkle tree to commit all messages
contract LaneMessageCommitter is MessageCommitter {
    /// @dev Governance role to set lanes config
    address public setter;
    /// @dev Count of all lanes in committer
    uint256 public laneCount;
    /// @dev Lane positon => lane address
    mapping(uint256 => address) public laneOf;

    /// @dev This chain position
    uint256 public immutable THIS_CHAIN_POSITION;
    /// @dev Bridged chain position
    uint256 public immutable BRIDGED_CHAIN_POSITION;

    event Registry(uint256 outLanePos, address outboundLane, uint256 inLanePos, address inboundLane);
    event ChangeLane(uint256 pos, address lane);

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    /// @dev Constructor params
    /// @param _thisChainPosition This chain positon
    /// @param _bridgedChainPosition Bridged chain positon
    constructor(uint256 _thisChainPosition, uint256 _bridgedChainPosition) {
        require(_thisChainPosition != _bridgedChainPosition, "!pos");
        THIS_CHAIN_POSITION = _thisChainPosition;
        BRIDGED_CHAIN_POSITION = _bridgedChainPosition;
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

    /// @dev Registry a pair of out lane and in lane, could not remove them
    /// @notice Only could be called by setter
    /// @param outboundLane Address of outbound lane
    /// @param inboundLane Address of inbound lane
    function registry(address outboundLane, address inboundLane) external onlySetter {
        (uint32 _thisChainPositionOut, uint32 _thisLanePositionOut, uint32 _bridgedChainPositionOut, ) = ILane(outboundLane).getLaneInfo();
        (uint32 _thisChainPositionIn, uint32 _thisLanePositionIn, uint32 _bridgedChainPositionIn, ) = ILane(inboundLane).getLaneInfo();
        require(THIS_CHAIN_POSITION == _thisChainPositionOut, "!thisChainPosition");
        require(THIS_CHAIN_POSITION == _thisChainPositionIn, "!thisChainPosition");
        require(BRIDGED_CHAIN_POSITION == _bridgedChainPositionOut, "!bridgedChainPosition");
        require(BRIDGED_CHAIN_POSITION == _bridgedChainPositionIn, "!bridgedChainPosition");
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
