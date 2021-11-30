// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IMappingTokenFactory {
    function newErc20Contract(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address backingAddress,
        uint32 tokenType,
        address originalToken,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external returns (address mappingToken);
    function issueMappingToken(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address backingAddress,
        address originalToken,
        address recipient,
        uint256 amount
    ) external;
}
     
