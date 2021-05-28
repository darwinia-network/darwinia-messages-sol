// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./Blake2b.sol";

contract Blake2bTest {
    using Blake2b for Blake2b.Instance;

    function testOneBlock32(bytes memory input) view public returns (bytes32) {
      Blake2b.Instance memory instance = Blake2b.init(hex"", 32);
      return bytesToBytes32(instance.finalize(input), 0);
    }

    function getSlice(uint256 begin, uint256 end, bytes memory text) public pure returns (bytes memory) {
        bytes memory temp = new bytes(end-begin+1);
        for(uint i=0; i <= end-begin; i++){
            temp[i] = text[i+begin];
        }
        return temp;
    }

    function bytesToBytes32(bytes memory b, uint256 offset)
        private
        pure
        returns (bytes32)
    {
        bytes32 out;

        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }
}
