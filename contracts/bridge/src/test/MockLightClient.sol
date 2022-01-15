// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
pragma abicoder v2;

contract MockLightClient {
    function verify_messages_proof(
        bytes32,
        uint32,
        uint32,
        bytes calldata
    ) external pure returns (bool) {
        return true;
    }

    function verify_messages_delivery_proof(
        bytes32,
        uint32,
        uint32,
        bytes calldata
    ) external pure returns (bool) {
        return true;
    }
}
