// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

contract MockBLS {
        function fast_aggregate_verify(
            bytes[] calldata,
            bytes calldata,
            bytes calldata
        ) external pure returns (bool) {
            return true;
        }
}
