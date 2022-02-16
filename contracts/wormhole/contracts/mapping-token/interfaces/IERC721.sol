// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/token/ERC721/IERC721.sol";

interface IErc721MappingToken {
    function initialize(string memory name, string memory symbol) external;
    function burn(uint256 id) external;
    function mint(address recipient, uint256 tokenId) external;
}
