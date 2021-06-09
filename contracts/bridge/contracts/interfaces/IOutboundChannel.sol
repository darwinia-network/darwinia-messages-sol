// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

interface IOutboundChannel {
    function submit(address origin, bytes calldata payload) external;
}
