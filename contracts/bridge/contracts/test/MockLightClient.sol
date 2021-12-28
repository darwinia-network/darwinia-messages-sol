// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

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
