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

import "../../utils/Math.sol";
import "../../spec/MessageProof.sol";
import "../../interfaces/IMessageCommitter.sol";

abstract contract MessageCommitter is Math {
    function count() public view virtual returns (uint256);
    function leaveOf(uint256 pos) public view virtual returns (address);

    /// @dev Get the commitment of all leaves
    /// @notice Return bytes(0) if there is no leave
    /// @return Commitment of this committer
    function commitment() public view returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](get_power_of_two_ceil(count()));
        unchecked {
            for (uint256 pos = 0; pos < count(); pos++) {
                hashes[pos] = commitment(pos);
            }
            uint256 hashLength = hashes.length;
            for (uint256 j = 0; hashLength > 1; j = 0) {
                for (uint256 i = 0; i < hashLength; i = i + 2) {
                    hashes[j] = hash_node(hashes[i], hashes[i + 1]);
                    j = j + 1;
                }
                hashLength = hashLength - j;
            }
        }
        return hashes[0];
    }

    /// @dev Get the commitment of the leaf
    /// @notice Return bytes(0) if the leaf address is address(0)
    /// @param pos Positon of the leaf
    /// @return Commitment of the leaf
    function commitment(uint256 pos) public view returns (bytes32) {
        address leaf = leaveOf(pos);
        if (leaf == address(0)) {
            return bytes32(0);
        } else {
            return IMessageCommitter(leaf).commitment();
        }
    }
    /// @dev Construct a Merkle Proof for leave given by position.
    function proof(uint256 pos) public view returns (MessageSingleProof memory) {
        bytes32[] memory tree = merkle_tree();
        uint depth = log_2(get_power_of_two_ceil(count()));
        require(pos < count(), "!pos");
        return MessageSingleProof({
            root: root(tree),
            proof: get_proof(tree, depth, pos)
        });
    }

    function root(bytes32[] memory tree) public pure returns (bytes32) {
        require(tree.length > 1, "!tree");
        return tree[1];
    }

    function merkle_tree() public view returns (bytes32[] memory) {
        uint num_leafs = get_power_of_two_ceil(count());
        uint num_nodes = 2 * num_leafs;
        uint depth = log_2(num_leafs);
        require(2**depth == num_leafs, "!depth");
        bytes32[] memory tree = new bytes32[](num_nodes);
        unchecked {
            for (uint i = 0; i < count(); i++) {
                tree[num_leafs + i] = commitment(i);
            }
            for (uint i = num_leafs - 1; i > 0; i--) {
                tree[i] = hash_node(tree[i * 2], tree[i * 2 + 1]);
            }
        }
        return tree;
    }

    function get_proof(bytes32[] memory tree, uint256 depth, uint256 pos) internal pure returns (bytes32[] memory) {
        bytes32[] memory decommitment = new bytes32[](depth);
        unchecked {
            uint256 index = (1 << depth) + pos;
            for (uint i = 0; i < depth; i++) {
                if (index & 1 == 0) {
                    decommitment[i] = tree[index + 1];
                } else {
                    decommitment[i] = tree[index - 1];
                }
                index = index >> 1;
            }
        }
        return decommitment;
    }

    function hash_node(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
    }
}
