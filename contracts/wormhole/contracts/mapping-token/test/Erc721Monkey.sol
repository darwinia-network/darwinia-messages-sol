// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import "../interfaces/IErc721AttrSerializer.sol";
import "../../utils/Ownable.sol";
import "../interfaces/IERC721.sol";
import "../v2/Erc721MappingToken.sol";

contract Erc721Monkey is Erc721MappingToken {
    // some changable attributes
    struct Attributes {
        uint age;
        uint weight;
    }
    mapping(uint256 => Attributes) private _attributes;

    function setAttr(uint256 id, uint age, uint weight) external {
        _attributes[id] = Attributes(age, weight);
    }

    function getAge(uint256 id) external view returns(uint) {
        return _attributes[id].age;
    }

    function getWeight(uint256 id) external view returns(uint) {
        return _attributes[id].weight;
    }

    function Serialize(uint256 id) external override returns(bytes memory) {
        return abi.encode(_attributes[id]);
    }

    function Deserialize(uint256 id, bytes memory data) external override onlyOwner {
        Attributes memory attr = abi.decode(data, (Attributes));
        _attributes[id] = attr;
    }
}

