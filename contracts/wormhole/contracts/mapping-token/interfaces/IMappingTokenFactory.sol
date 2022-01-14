// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IMappingTokenFactory {
    function newErc20Contract(
        address backingAddress,
        uint32 tokenType,
        address originalToken,
        string memory bridgedChainName,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external returns (address mappingToken);
    function issueMappingToken(
        address backingAddress,
        address originalToken,
        address recipient,
        uint256 amount
    ) external;
}
     
