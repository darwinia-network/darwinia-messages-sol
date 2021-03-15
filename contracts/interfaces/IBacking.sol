// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

interface IBacking {
    function crossChainSync(
        bytes memory message,
        bytes[] memory signatures,
        bytes32 root,
        uint32 MMRIndex,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory eventsProofStr
    ) external;
    function crossSendToken(
        address token,
        address recipient,
        uint256 amount) external;
}
