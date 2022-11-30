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

import "../../spec/StorageProof.sol";
import "../../spec/ChainMessagePosition.sol";
import "../../interfaces/ILightClient.sol";

contract EthereumParallelLaneStorageVerifier {
    struct Proof {
        bytes accountProof;
        bytes laneRootProof;
    }

    // chain_pos ++ lane_pos
    uint256 public immutable LINDEX;
    uint256 public immutable LANE_ROOT_SLOT;
    address public immutable LIGHT_CLIENT;
    address public immutable PARALLEL_OUTLANE;

    constructor(
        uint256 lindex,
        uint256 lane_root_slot,
        address light_client,
        address parallel_outlane
    ) {
        LINDEX = lindex;
        LANE_ROOT_SLOT = lane_root_slot;
        LIGHT_CLIENT = light_client;
        PARALLEL_OUTLANE = parallel_outlane;
    }

    function state_root() public view returns (bytes32) {
        return ILightClient(LIGHT_CLIENT).merkle_root();
    }

    function verify_lindex(uint32 chain_pos, uint32 lane_pos) internal view returns (bool) {
        return LINDEX == ((chain_pos << 32) + lane_pos);
    }

    function verify_messages_proof(
        bytes32 outlane_commitment,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool) {
        require(verify_lindex(chain_pos, lane_pos), "!lindex");
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

        // check outlane_commitment correct
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
}
