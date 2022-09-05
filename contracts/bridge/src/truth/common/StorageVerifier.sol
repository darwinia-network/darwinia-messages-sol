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
import "../../spec/SourceChain.sol";
import "../../spec/TargetChain.sol";
import "../../spec/StorageProof.sol";

abstract contract StorageVerifier is IVerifier, SourceChain, TargetChain {
    event Registry(uint256 bridgedChainPosition, uint256 lanePosition, address lane);

    struct ReceiveProof {
        bytes accountProof;
        bytes laneIDProof;
        bytes laneNonceProof;
        bytes[] laneMessagesProof;
    }

    struct DeliveryProof {
        bytes accountProof;
        bytes laneNonceProof;
        bytes[] laneRelayersProof;
    }

    uint256 public immutable THIS_CHAIN_POSITION;
    uint256 public immutable LANE_IDENTIFY_SLOT;
    uint256 public immutable LANE_NONCE_SLOT;
    uint256 public immutable LANE_MESSAGE_SLOT;

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
        uint256 lane_identify_slot,
        uint256 lane_nonce_slot,
        uint256 lane_message_slot
    ) {
        THIS_CHAIN_POSITION = this_chain_position;
        LANE_IDENTIFY_SLOT = lane_identify_slot;
        LANE_NONCE_SLOT = lane_nonce_slot;
        LANE_MESSAGE_SLOT = lane_message_slot;
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
        ReceiveProof memory proof = abi.decode(encoded_proof, (ReceiveProof));

        // extract identify storage value from proof
        uint identify_storage = toUint(StorageProof.verify_single_storage_proof(
            state_root(),
            lane,
            proof.accountProof,
            bytes32(LANE_IDENTIFY_SLOT),
            proof.laneIDProof
        ));

        // extract nonce storage value from proof
        uint nonce_storage = toUint(StorageProof.verify_single_storage_proof(
            state_root(),
            lane,
            proof.accountProof,
            bytes32(LANE_NONCE_SLOT),
            proof.laneNonceProof
        ));

        OutboundLaneDataStorage memory lane_data = build_outlane(identify_storage, nonce_storage, lane, proof);
        // check the lane_data_hash
        return outlane_hash == hash(lane_data);
    }

    function build_outlane(uint identify_storage, uint nonce_storage, address lane, ReceiveProof memory proof) internal view returns (OutboundLaneDataStorage memory lane_data) {
        // restruct the outlane data
        uint64 latest_received_nonce = uint64(nonce_storage);
        uint64 size = uint64(nonce_storage >> 64) - latest_received_nonce;
        if (size > 0) {
            // find all messages storage keys
            bytes32[] memory storage_keys = build_message_keys(latest_received_nonce, size);

            // extract messages storage value from proof
            bytes[] memory values = StorageProof.verify_multi_storage_proof(
                state_root(),
                lane,
                proof.accountProof,
                storage_keys,
                proof.laneMessagesProof
            );

            require(size == values.length, "!values_len");
            MessageStorage[] memory messages = new MessageStorage[](size);
            for (uint64 i=0; i < size; i++) {
               bytes32 payload = toBytes32(values[i]);
               uint256 key = (identify_storage << 64) + latest_received_nonce + 1 + i;
               messages[i] = MessageStorage(key, payload);
            }
            lane_data.messages = messages;
        }
        lane_data.latest_received_nonce = latest_received_nonce;
    }

    function build_message_keys(uint64 latest_received_nonce, uint64 size) internal view returns (bytes32[] memory) {
        bytes32[] memory storage_keys = new bytes32[](size);
        uint64 begin = latest_received_nonce + 1;
        for (uint64 index=0; index < size;) {
            storage_keys[index++] = bytes32(mapLocation(LANE_MESSAGE_SLOT, begin + index));
        }
        return storage_keys;
    }

    function verify_messages_delivery_proof(
        bytes32 inlane_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view override returns (bool) {
        address lane = lanes[chain_pos][lane_pos];
        require(lane != address(0), "!inlane");
        DeliveryProof memory proof = abi.decode(encoded_proof, (DeliveryProof));

        // extract nonce storage value from proof
        uint nonce_storage = toUint(StorageProof.verify_single_storage_proof(
            state_root(),
            lane,
            proof.accountProof,
            bytes32(LANE_NONCE_SLOT),
            proof.laneNonceProof
        ));

        uint64 last_confirmed_nonce = uint64(nonce_storage);
        uint64 last_delivered_nonce = uint64(nonce_storage >> 64);
        uint64 front = uint64(nonce_storage >> 128);
        uint64 back = uint64(nonce_storage >> 192);
        uint64 size = back >= front ? back - front + 1 : 0;
        // restruct the in lane data
        InboundLaneData memory lane_data = build_inlane(size, front, last_confirmed_nonce, last_delivered_nonce, lane, proof);
        // check the lane_data_hash
        return inlane_hash == hash(lane_data);
    }

    function build_inlane(
        uint64 size,
        uint64 front,
        uint64 last_confirmed_nonce,
        uint64 last_delivered_nonce,
        address lane,
        DeliveryProof memory proof
    ) internal view returns (InboundLaneData memory lane_data) {
        // restruct the in lane data
        if (size > 0) {
            uint64 len = 2 * size;
            // find all messages storage keys
            bytes32[] memory storage_keys = new bytes32[](len);
            for (uint64 index=0; index < len;) {
                uint256 relayersLocation = mapLocation(LANE_MESSAGE_SLOT, front + index/2);
                storage_keys[index++] = bytes32(relayersLocation);
                storage_keys[index++] = bytes32(relayersLocation + 1);
            }

            // extract messages storage value from proof
            bytes[] memory values = StorageProof.verify_multi_storage_proof(
                state_root(),
                lane,
                proof.accountProof,
                storage_keys,
                proof.laneRelayersProof
            );

            require(len == values.length, "!values_len");
            UnrewardedRelayer[] memory unrewarded_relayers = new UnrewardedRelayer[](size);
            for (uint64 i=0; i < size; i++) {
               uint slot2 = toUint(values[2*i+1]);
               unrewarded_relayers[i] = UnrewardedRelayer(
                   address(uint160(toUint(values[2*i]))),
                   DeliveredMessages(
                       uint64(slot2),
                       uint64(slot2 >> 64)
                   )
               );
            }
            lane_data.relayers = unrewarded_relayers;
        }
        lane_data.last_confirmed_nonce = last_confirmed_nonce;
        lane_data.last_delivered_nonce = last_delivered_nonce;
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

    function mapLocation(uint256 slot, uint256 key) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(key, slot)));
    }
}
