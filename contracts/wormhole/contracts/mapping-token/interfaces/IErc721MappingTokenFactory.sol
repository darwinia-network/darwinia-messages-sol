// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc721MappingTokenFactory {
    function newErc721Contract(
        address backingAddress,
        uint32 tokenType,
        address originalToken,
        string memory bridgedChainName,
        string memory name,
        string memory symbol
    ) external returns (address mappingToken);

    function issueMappingToken(
        address backingAddress,
        address originalToken,
        address recipient,
        uint256[] calldata ids
    ) external;
}
     
