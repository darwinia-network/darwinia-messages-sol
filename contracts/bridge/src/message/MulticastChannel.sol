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
import "../interfaces/IUserConfig.sol";
import "../interfaces/IHashOracle.sol";
import "../interfaces/IMessageVerifier.sol";
import "../utils/imt/IncrementalMerkleTree.sol";

interface IEndpoint {
    function recv(Message calldata message) external returns (bool dispatch_result);
}

/// @title MulticastChannel
/// @notice Accepts messages to be dispatched to remote chains,
/// constructs a Merkle tree of the messages.
/// @dev TODO: doc
contract MulticastChannel is LibMessage {
    using IncrementalMerkleTree for IncrementalMerkleTree.Tree;
    /// @dev slot 0, messages root
    bytes32 private root;
    /// @dev incremental merkle tree
    IncrementalMerkleTree.Tree private imt;

    mapping(bytes32 => bool) public dones;

    address public immutable ENDPOINT;
    address public immutable CONFIG;
    uint32  public immutable LOCAL_CHAINID;

    event MessageAccepted(uint32 indexed index, bytes32 indexed msg_hash, bytes32 root, Message message);
    event MessageDispatched(bytes32 indexed msg_hash, bool dispatch_result);

    modifier onlyEndpoint {
        require(msg.sender == ENDPOINT, "!endpoint");
        _;
    }

    constructor(uint32 localChainId, address endpoint, address config) {
        // init with empty tree
        root = 0x27ae5ba08d7291c96c8cbddcc148bf48a6d68c7974b94356f53754ef6171d757;
        LOCAL_CHAINID = localChainId;
        ENDPOINT = endpoint;
        CONFIG = config;
    }

    /// @dev Send message over lane.
    function send_message(
        address from,
        uint32 toChainId,
        address to,
        bytes calldata encoded
    ) external onlyEndpoint returns (uint32) {
        uint32 index = message_size();
        Message memory message = Message({
            index: index,
            fromChainId: LOCAL_CHAINID,
            from: from,
            toChainId: toChainId,
            to: to,
            encoded: encoded
        });
        bytes32 msg_hash = hash(message);
        imt.insert(msg_hash);
        root = imt.root();

        emit MessageAccepted(
            index,
            msg_hash,
            root,
            message
        );

        return index;
    }

    /// Receive messages proof from bridged chain.
    function recv_message(
        Message calldata message,
        bytes calldata proof
    ) external {
        Config memory uaConfig = IUserConfig(CONFIG).getAppConfig(message.fromChainId, message.to);
        bytes32 merkle_root = IHashOracle(uaConfig.oracle).merkle_root(message.fromChainId);
        // check message is from the correct source chain position
        IMessageVerifier(uaConfig.verifier).verify_message_proof(
            message.fromChainId,
            merkle_root,
            hash(message),
            proof
        );

        require(LOCAL_CHAINID == message.toChainId, "InvalidTargetLaneId");
        bytes32 msg_hash = hash(message);
        require(dones[msg_hash] == false, "done");
        dones[msg_hash] = true;

        // then, dispatch message
        bool dispatch_result = IEndpoint(ENDPOINT).recv(message);
        emit MessageDispatched(msg_hash, dispatch_result);
    }

    /// Return the commitment of lane data.
    function commitment() external view returns (bytes32) {
        return root;
    }

    function message_size() public view returns (uint32) {
        return uint32(imt.count);
    }

    function imt_branch() public view returns (bytes32[32] memory) {
        return imt.branch;
    }
}
