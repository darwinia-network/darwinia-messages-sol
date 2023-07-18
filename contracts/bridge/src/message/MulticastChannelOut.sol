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

import "../spec/LibMessage.sol";
import "../utils/imt/IncrementalMerkleTree.sol";

/// @title MulticastChannelOut
/// @notice Accepts messages to be dispatched to remote chains,
/// constructs a Merkle tree of the messages.
/// @dev TODO: doc
contract MulticastChannelOut is LibMessage {
    using IncrementalMerkleTree for IncrementalMerkleTree.Tree;
    /// @dev slot 0, messages root
    bytes32 private root;
    /// @dev slot [1, 33] incremental merkle tree
    IncrementalMerkleTree.Tree private imt;

    address public endpoint;
    // toChainId => next available nonce
    mapping(uint32 => uint32) public nonceOf;

    uint32 immutable public localChainId;

    event MessageAccepted(uint64 indexed index, bytes32 root, Message encoded);

    modifier onlyEndpoint {
        require(msg.sender == endpoint, "!endpoint");
        _;
    }

    constructor(uint32 localChainId_) {
        // init with empty tree
        root = 0x27ae5ba08d7291c96c8cbddcc148bf48a6d68c7974b94356f53754ef6171d757;
        localChainId = localChainId_;
    }

    /// @dev Send message over lane.
    function send_message(
        uint32 toChainId,
        address to,
        bytes calldata encoded
    ) external onlyEndpoint {
        // get the next nonce for the to chain, then increment it
        uint32 _nonce = nonceOf[toChainId];
        nonceOf[toChainId] = _nonce + 1;
        Message memory message = Message({
            fromChainId: localChainId,
            from: msg.sender,
            nonce: _nonce,
            toChainId: toChainId,
            to: to,
            encoded: encoded
        });
        bytes32 msg_hash = hash(message);
        imt.insert(msg_hash);
        root = imt.root();

        emit MessageAccepted(
            message_size() - 1,
            root,
            message
        );
    }

    /// Return the commitment of lane data.
    function commitment() external view returns (bytes32) {
        return root;
    }

    function message_size() public view returns (uint64) {
        return uint64(imt.count);
    }

    function imt_branch() public view returns (bytes32[32] memory) {
        return imt.branch;
    }
}
