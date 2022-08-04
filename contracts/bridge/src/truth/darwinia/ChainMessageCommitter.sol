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
import "../../interfaces/IMessageCommitment.sol";

/// @title ChainMessageCommitter
/// @author echo
/// @notice Chain message committer commit messages from all lane committers
/// @dev Chain message use sparse merkle tree to commit all messages
contract ChainMessageCommitter is Math {
    event Registry(uint256 pos, address committer);

    /// @dev This chain position
    uint256 public immutable thisChainPosition;
    /// @dev Max of all chain position
    uint256 public maxChainPosition;
    /// @dev Bridged chain position => lane committer
    mapping(uint256 => address) public chainOf;
    /// @dev Governance role to set chains config
    address public setter;

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    /// @dev Constructor params
    /// @param _thisChainPosition This chain positon
    constructor(uint256 _thisChainPosition) {
        thisChainPosition = _thisChainPosition;
        maxChainPosition = _thisChainPosition;
        setter = msg.sender;
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
        uint256 pos = IMessageCommitment(committer).bridgedChainPosition();
        require(thisChainPosition != pos, "!bridgedChainPosition");
        require(thisChainPosition == IMessageCommitment(committer).thisChainPosition(), "!thisChainPosition");
        chainOf[pos] = committer;
        maxChainPosition = max(maxChainPosition, pos);
        emit Registry(pos, committer);
    }

    /// @dev Get the commitment of a lane committer
    /// @notice Return bytes(0) if the lane committer address is address(0)
    /// @param chainPos Bridged chian positon of the lane committer
    /// @return Commitment of the lane committer
    function commitment(uint256 chainPos) public view returns (bytes32) {
        address committer = chainOf[chainPos];
        if (committer == address(0)) {
            return bytes32(0);
        } else {
            return IMessageCommitment(committer).commitment();
        }
    }

    /// @dev Get the commitment of all lane committers
    /// @notice Return bytes(0) if there is no lane committer
    /// @return Commitment of this chian committer
    function commitment() public view returns (bytes32) {
        uint256 chainCount = maxChainPosition + 1;
        bytes32[] memory hashes = new bytes32[](get_power_of_two_ceil(chainCount));
        for (uint256 pos = 0; pos < chainCount; pos++) {
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
