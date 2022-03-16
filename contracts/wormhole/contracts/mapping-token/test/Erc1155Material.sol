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

    function serialize(uint256[] memory ids) external view returns(bytes[] memory) {
        bytes[] memory attrs = new bytes[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            attrs[i] = abi.encode(_attributes[ids[i]]);
        }
        return attrs;
    }

    function deserialize(uint256[] memory ids, bytes[] memory data) external {
        require(ids.length == data.length, "invalid data length");
        for (uint256 i = 0; i < ids.length; i++) {
            Attributes memory attr = abi.decode(data[i], (Attributes));
            _attributes[ids[i]] = attr;
        }
    }
}

