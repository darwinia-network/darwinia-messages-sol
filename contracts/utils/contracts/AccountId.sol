// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./Bytes.sol";

library AccountId {
    bytes private constant prefixBytes = "dvm:";
    bytes private constant zeroBytes = hex"00000000000000";

    function fromAddress(address addr) internal pure returns (bytes32) {
        bytes memory addrBytes = abi.encodePacked(addr);

        bytes memory body = Bytes.concat(
            Bytes.concat(prefixBytes, zeroBytes),
            addrBytes
        );
        uint8 checksum = checksumOf(body);
        bytes memory result = abi.encodePacked(body, checksum);
        return Bytes.toBytes32(result);
    }

    function deriveSubstrateAddress(address addr) internal pure returns (bytes32) {
        return fromAddress(addr);
    }

    function deriveEthereumAddress(bytes32 accountId) internal pure returns (address) {
        bytes memory accountIdBytes = abi.encodePacked(accountId);
        if (isDerivedSubstrateAddress(accountIdBytes)) {
            return bytesToAddress(Bytes.substr(accountIdBytes, 11, 20));
        } else {
            return bytesToAddress(Bytes.substr(accountIdBytes, 0, 20));
        }
    }

    function isDerivedSubstrateAddress(bytes memory accountIdBytes) internal pure returns (bool) {
        bytes memory prefix = Bytes.concat(prefixBytes, zeroBytes);
        bool correct_prefix = Bytes.equals(Bytes.substr(accountIdBytes, 0, 11), prefix);
        bool correct_checksum = Bytes.equals(Bytes.substr(accountIdBytes, 31), abi.encodePacked(checksumOf(accountIdBytes)));
        return correct_prefix && correct_checksum;
    }

    function checksumOf(bytes memory accountId) private pure returns (uint8) {
        uint8 checksum = uint8(accountId[0]);
        for (uint i = 1; i <= 30; i++) {
            checksum = checksum ^ uint8(accountId[i]);
        }
        return checksum;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        } 
    }
}