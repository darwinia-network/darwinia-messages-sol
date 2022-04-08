// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc20MappingTokenFactory {
    function newErc20Contract(
        uint32 tokenType,
        address originalToken,
        string memory bridgedChainName,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external returns (address mappingToken);
    function issueMappingToken(
        address originalToken,
        address recipient,
        uint256 amount
    ) external;
}
     
