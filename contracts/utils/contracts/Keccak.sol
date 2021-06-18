// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

library Keccak {

    function hash(bytes memory src) internal pure returns (bytes32 des) {
        return keccak256(src);
    }
}
