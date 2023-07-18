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

import "../interfaces/ILightClient.sol";
import "../interfaces/IMessageVerifier.sol";
import "../spec/StorageProof.sol";
import "../utils/imt/IncrementalMerkleTree.sol";

contract MulticastChannelOutVerifier is IMessageVerifier {
    event Registry(uint32 indexed fromChainId, address out);

    bytes32 public immutable IMT_ROOT_SLOT;
    address public immutable LIGHT_CLIENT;

    // from chain id => multicast channel out
    mapping(uint32 => address) public channelOf;
    address public setter;

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    function changeSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    constructor(bytes32 imtRootSlot, address oracle) {
        IMT_ROOT_SLOT = imtRootSlot;
        LIGHT_CLIENT = oracle;
        setter = msg.sender;
    }

    function registry(uint32 fromChainId, address out) external onlySetter {
        require(channelOf[fromChainId] == address(0), "!empty");
        channelOf[fromChainId] = out;
        emit Registry(fromChainId, out);
    }

    function state_root() public view returns (bytes32) {
        return ILightClient(LIGHT_CLIENT).merkle_root();
    }

    function verify_message_proof(
        uint32 fromChainId,
        bytes32 msg_root,
        Proof calldata proof
    ) external view returns (bool) {
        // extract imt root storage value from proof
        bytes32 imt_root_storage = toBytes32(StorageProof.verify_single_storage_proof(
            state_root(),
            channelOf[fromChainId],
            proof.accountProof,
            IMT_ROOT_SLOT,
            proof.imtRootProof
        ));

        // calculate the expected root based on the proof
        bytes32 imt_root_proof = IncrementalMerkleTree.branchRoot(
            msg_root,
            proof.messageProof,
            proof.messageIndex
        );

        return imt_root_storage == imt_root_proof;
    }

    function toBytes32(bytes memory bts) internal pure returns (bytes32 data) {
        uint len = bts.length;
        if (len == 0) {
            return bytes32(0);
        }
        require(len <= 32, "!len");
        assembly ("memory-safe") {
            data := div(mload(add(bts, 32)), exp(256, sub(32, len)))
        }
    }
}
