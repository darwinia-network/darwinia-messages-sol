// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

interface ILightClient {
    function verify_messages_proof(
        bytes32 outboundLaneDataHash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata proof
    ) external view returns (bool);

    function verify_messages_delivery_proof(
        bytes32 inboundLaneDataHash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata proof
    ) external view returns (bool);
}
