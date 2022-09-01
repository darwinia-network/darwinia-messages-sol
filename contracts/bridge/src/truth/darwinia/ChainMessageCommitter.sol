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

import "../common/MessageCommitter.sol";
import "../../interfaces/IMessageCommitter.sol";
import "../../proxy/Initializable.sol";

/// @title ChainMessageCommitter
/// @author echo
/// @notice Chain message committer commit messages from all lane committers
/// @dev Chain message use sparse merkle tree to commit all messages
contract ChainMessageCommitter is Initializable, MessageCommitter {
    /// @dev Max of all chain position
    uint256 public maxChainPosition;
    /// @dev Bridged chain position => lane committer
    mapping(uint256 => address) public chainOf;
    /// @dev Governance role to set chains config
    address public setter;

    /// @dev This chain position
    uint256 public immutable thisChainPosition;

    event Registry(uint256 pos, address committer);

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    /// @dev Constructor params
    /// @param _thisChainPosition This chain positon
    constructor(uint256 _thisChainPosition) {
        thisChainPosition = _thisChainPosition;
    }

    function initialize() public initializer {
        __CMC_init__(msg.sender);
    }

    function __CMC_init__(address _setter) internal onlyInitializing {
        maxChainPosition = thisChainPosition;
        setter = _setter;
    }

    function count() public view override returns (uint256) {
        return maxChainPosition + 1;
    }

    function leaveOf(uint256 pos) public view override returns (address) {
        return chainOf[pos];
    }

    /// @dev Change the setter
    /// @notice Only could be called by setter
    /// @param _setter The new setter
    function changeSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    /// @dev Registry a lane committer
    /// @notice Only could be called by setter
    /// @param committer Address of lane committer
    function registry(address committer) external onlySetter {
        uint256 pos = IMessageCommitter(committer).bridgedChainPosition();
        require(thisChainPosition != pos, "!bridgedChainPosition");
        require(thisChainPosition == IMessageCommitter(committer).thisChainPosition(), "!thisChainPosition");
        chainOf[pos] = committer;
        maxChainPosition = max(maxChainPosition, pos);
        emit Registry(pos, committer);
    }

    /// @dev Get message proof for lane
    /// @param chainPos Bridged chain position of lane
    /// @param lanePos This lane positon of lane
    function prove(uint256 chainPos, uint256 lanePos) external view returns (MessageProof memory) {
        address committer = leaveOf(chainPos);
        return MessageProof({
            chainProof: proof(chainPos),
            laneProof: IMessageCommitter(committer).proof(lanePos)
        });
    }
}
