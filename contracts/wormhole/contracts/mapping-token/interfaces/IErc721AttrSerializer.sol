// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc721AttrSerializer {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function Serialize(uint256 id) external view returns(bytes memory);
    function Deserialize(uint256 id, bytes memory data) external;
}
