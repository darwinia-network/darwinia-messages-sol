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

import "../common/ParallelLaneStorageVerifier.sol";
import "../../interfaces/IVerifier.sol";
import "../../spec/StorageProof.sol";
import "../../spec/ChainMessagePosition.sol";
import "../../interfaces/ILightClient.sol";

contract EthereumParallelLaneStorageVerifier is IVerifier {
    struct Proof {
        bytes accountProof;
        bytes laneRootProof;
    }

    uint256 public immutable GINDEX;
    uint256 public immutable LANE_ROOT_SLOT;
    address public immutable LIGHT_CLIENT;
    address public immutable PARALLEL_OUTLANE;

    constructor(
        uint256 gindex,
        uint256 lane_root_slot,
        address lightclient,
        address parallel_outlane
    ) {
        light_client = lightclient;
    }

    function state_root() public view override returns (bytes32) {
        return ILightClient(light_client).merkle_root();
    }

    function verify_gindex(uint32 chain_pos, uint32 lane_pos) public pure returns (bool) {
        //TODO
        return false;
    }

    function verify_messages_proof(
        bytes32 outlane_commitment,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view override returns (bool) {
        require(verify_gindex(chain_pos, lane_pos), "!gindex");
        Proof memory proof = abi.decode(encoded_proof, (Proof));

        // extract root storage value from proof
        bytes32 root_storage = toBytes32(
            StorageProof.verify_single_storage_proof(
                state_root(),
                PARALLEL_OUTLANE,
                proof.accountProof,
                bytes32(LANE_ROOT_SLOT),
                proof.laneRootProof
            )
        );

        // check the lane_data_hash
        return outlane_commitment == root_storage;
    }

    function toUint(bytes memory bts) internal pure returns (uint data) {
        uint len = bts.length;
        if (len == 0) {
            return 0;
        }
        require(len <= 32, "!len");
        assembly {
            data := div(mload(add(bts, 32)), exp(256, sub(32, len)))
        }
    }

    function toBytes32(bytes memory bts) internal pure returns (bytes32 data) {
        return bytes32(toUint(bts));
    }

    // TODO: remove
    function verify_messages_delivery_proof(
        bytes32,
        uint32,
        uint32,
        bytes calldata
    ) external pure override returns (bool) {
        return false;
    }
}
