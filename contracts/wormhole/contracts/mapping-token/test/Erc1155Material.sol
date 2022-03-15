// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import "../interfaces/IErc1155AttrSerializer.sol";
import "../../utils/Ownable.sol";
import "../interfaces/IErc1155MappingToken.sol";

contract Erc1155MaterialAttributeSerializer is IErc1155AttrSerializer {
    // some changable attributes
    // id = 0 ----- brick
    // id = 1 ----- rebar

    struct Attributes {
        string source;
        string name;
        uint256 level;
    }
    mapping(uint256 => Attributes) private _attributes;

    function setAttr(uint256 id, string memory source, string memory name, uint256 level) external {
        _attributes[id] = Attributes(source, name, level);
    }

    function getSource(uint256 id) external view returns(string memory) {
        return _attributes[id].source;
    }

    function getName(uint256 id) external view returns(string memory) {
        return _attributes[id].name;
    }

    function getLevel(uint256 id) external view returns(uint256) {
        return _attributes[id].level;
    }

    function uri(uint256 tokenId) external pure returns(string memory) {
        return "";
    }

    function serialize(uint256 id) external view returns(bytes memory) {
        return abi.encode(_attributes[id]);
    }

    function deserialize(uint256 id, bytes memory data) external {
        Attributes memory attr = abi.decode(data, (Attributes));
        _attributes[id] = attr;
    }
}

