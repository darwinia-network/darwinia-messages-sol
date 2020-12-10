pragma solidity >=0.5.0 <0.6.0;

contract ISettingsRegistry {
    function addressOf(bytes32 _propertyName) public view returns (address);
    event ChangeProperty(bytes32 indexed _propertyName, uint256 _type);
}