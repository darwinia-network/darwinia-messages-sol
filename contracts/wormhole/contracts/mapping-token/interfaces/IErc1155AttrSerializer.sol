// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc1155AttrSerializer {
    function uri(uint256 tokenId) external view returns (string memory);
    function serialize(uint256[] memory ids) external view returns(bytes[] memory);
    function deserialize(uint256[] memory ids, bytes[] memory data) external;
}
