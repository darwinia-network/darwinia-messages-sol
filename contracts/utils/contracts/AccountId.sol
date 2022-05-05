// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./Bytes.sol";

library AccountId {
	function fromAddress(address addr) internal pure returns (bytes32) {
		bytes memory prefixBytes = "dvm:";
		bytes memory zeroBytes = hex"00000000000000";
		bytes memory addrBytes = abi.encodePacked(addr);

		bytes memory body = Bytes.concat(Bytes.concat(prefixBytes, zeroBytes), addrBytes);
		uint8 checksum = uint8(body[0]);
		for (uint i = 1; i <= 30; i++) {
			checksum = checksum ^ uint8(body[i]);
		}
		bytes memory result = abi.encodePacked(body, checksum);
		return Bytes.toBytes32(result);
    }
}