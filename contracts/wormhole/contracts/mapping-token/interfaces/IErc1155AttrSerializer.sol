// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc1155AttrSerializer {
    function uri(uint256 tokenId) external view returns (string memory);
    function Serialize(uint256 id) external view returns(bytes memory);
    function Deserialize(uint256 id, bytes memory data) external;
}
