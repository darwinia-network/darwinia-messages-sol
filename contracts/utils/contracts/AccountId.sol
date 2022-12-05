// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./Bytes.sol";

library AccountId {
    bytes private constant prefixBytes = "dvm:";
    bytes private constant zeroBytes = hex"00000000000000";

    function deriveSubstrateAddress(address addr) internal pure returns (bytes32) {
        bytes memory body = abi.encodePacked(
            prefixBytes,
            zeroBytes,
            addr
        );
        uint8 checksum = checksumOf(body);
        bytes memory result = abi.encodePacked(body, checksum);
        return Bytes.toBytes32(result);
    }

    function deriveEthereumAddress(bytes32 accountId) internal pure returns (address) {
        return address(bytes20(accountId));
    }

    function deriveEthereumAddressFromDvm(bytes32 accountId) internal pure returns (address) {
        return address(uint160(uint256(accountId) >> 8));
    }

    function checksumOf(bytes memory accountId) private pure returns (uint8) {
        uint8 checksum = uint8(accountId[0]);
        for (uint i = 1; i <= 30; i++) {
            checksum = checksum ^ uint8(accountId[i]);
        }
        return checksum;
    }
}