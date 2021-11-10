// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

contract MockLightClient {

    function verify_messages_proof(
        bytes32 ,
        bytes32 ,
        uint256 ,
        uint256 ,
        bytes calldata
    ) external pure returns (bool) {
        return true;
    }

    function verify_messages_delivery_proof(
        bytes32 ,
        bytes32 ,
        uint256 ,
        uint256 ,
        bytes calldata
    ) external pure returns (bool) {
        return true;
    }
}
