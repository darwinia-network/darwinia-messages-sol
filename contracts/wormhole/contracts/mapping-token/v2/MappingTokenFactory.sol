// SPDX-License-Identifier: MIT
// This is the Issuing Module(Mapping-token-factory) of the ethereum like bridge.
// We trust the inboundLane/outboundLane when we add them to the module.
// It means that each message from the inboundLane is verified correct and truthly from the sourceAccount.
// Only we need is to verify the sourceAccount is expected. And we add it to the Filter.
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/access/Ownable.sol";

contract MappingTokenFactory {
    address[] public allMappingTokens;
    // salt=>mappingToken, the salt is derived from origin token on backing chain
    // so this is a mapping from origin to mapping token
    mapping(bytes32 => address) public salt2MappingToken;
    // mappingToken=>info the info is the original token info
    // so this is a mapping from mappingToken to original token
    mapping(address => address) public mappingToken2OriginalToken;

    function _transferMappingTokenOwnership(address mappingToken, address new_owner) internal {
        Ownable(mappingToken).transferOwnership(new_owner);
    }

    /**
     * @notice add mapping-token address by owner
     * @param salt the salt of the mapping token deployed
     * @param originalToken the original token address
     * @param mappingToken the mapping token address
     */
    function _addMappingToken(
        bytes32 salt,
        address originalToken,
        address mappingToken
    ) internal {
        // save the mapping tokens in an array so it can be listed
        allMappingTokens.push(mappingToken);
        // map the originToken to mappingInfo
        salt2MappingToken[salt] = mappingToken;
        // map the mappingToken to origin info
        mappingToken2OriginalToken[mappingToken] = originalToken;
    }

    // internal
    function _deploy(bytes32 salt, bytes memory bytecodeWithInitdata) internal returns (address addr) {
        assembly {
            addr := create2(0, add(bytecodeWithInitdata, 0x20), mload(bytecodeWithInitdata), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function tokenLength() public view returns (uint) {
        return allMappingTokens.length;
    }

    function getMappingToken(uint32 bridgedChainPosition, address backingAddress, address originalToken) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(bridgedChainPosition, backingAddress, originalToken));
        return salt2MappingToken[salt];
    }
}

