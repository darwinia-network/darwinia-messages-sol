// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc721AttrSerializer {
    function Serialize(uint256 id) external returns(bytes memory);
    function Deserialize(uint256 id, bytes memory data) external;
}
