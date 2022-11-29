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

import "../../interfaces/IVerifier.sol";
import "../../spec/StorageProof.sol";

abstract contract BaseLaneStorageVerifier is IVerifier {
    event Registry(uint256 bridgedChainPosition, uint256 lanePosition, address lane);

    struct Proof {
        bytes accountProof;
        bytes laneRootProof;
    }

    uint256 public immutable THIS_CHAIN_POSITION;
    uint256 public immutable LANE_ROOT_SLOT;

    // bridgedChainPosition => lanePosition => lanes
    mapping(uint32 => mapping(uint32 => address)) public lanes;
    address public setter;

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    function changeSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    constructor(
        uint32 this_chain_position,
        uint256 lane_root_slot
    ) {
        THIS_CHAIN_POSITION = this_chain_position;
        LANE_ROOT_SLOT = lane_root_slot;
        setter = msg.sender;
    }

    function registry(uint32 bridgedChainPosition, uint32 outboundPosition, address outbound, uint32 inboundPositon, address inbound) external onlySetter {
        require(bridgedChainPosition != THIS_CHAIN_POSITION, "invalid_chain_pos");
        lanes[bridgedChainPosition][outboundPosition] = outbound;
        lanes[bridgedChainPosition][inboundPositon] = inbound;
        emit Registry(bridgedChainPosition, outboundPosition, outbound);
        emit Registry(bridgedChainPosition, inboundPositon, inbound);
    }

    function state_root() public view virtual returns (bytes32);

    function verify_messages_proof(
        bytes32 outlane_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view override returns (bool) {
        address lane = lanes[chain_pos][lane_pos];
        require(lane != address(0), "!outlane");
        Proof memory proof = abi.decode(encoded_proof, (Proof));

        // extract nonce storage value from proof
        bytes32 root_storage = toBytes32(
            StorageProof.verify_single_storage_proof(
                state_root(),
                lane,
                proof.accountProof,
                bytes32(LANE_ROOT_SLOT),
                proof.laneRootProof
            )
        );

        // check the lane_data_hash
        return outlane_hash == root_storage;
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

    function verify_messages_delivery_proof(
        bytes32,
        uint32,
        uint32,
        bytes calldata
    ) external pure override returns (bool) {
        return false;
    }
}
