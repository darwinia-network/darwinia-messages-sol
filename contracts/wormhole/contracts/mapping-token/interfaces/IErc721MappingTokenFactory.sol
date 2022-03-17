// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc721MappingTokenFactory {
    function newErc721Contract(
        address backingAddress,
        address originalToken,
        address attrSerializer,
        string memory bridgedChainName
    ) external returns (address mappingToken);

    function issueMappingToken(
        address backingAddress,
        address originalToken,
        address recipient,
        uint256[] calldata ids,
        bytes[] calldata attrs
    ) external;
}
     
