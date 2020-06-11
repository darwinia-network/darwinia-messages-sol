pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Blake2b.sol";

contract Blake2bTest {
    using Blake2b for Blake2b.Instance;

    function testOneBlock(bytes memory input) public returns (bytes memory) {
        Blake2b.Instance memory instance = Blake2b.init(hex"", 64);
        return instance.finalize(input);
    }

    function getSlice(uint256 begin, uint256 end, bytes memory text) public returns (bytes memory) {
        bytes memory temp = new bytes(end-begin+1);
        for(uint i=0; i <= end-begin; i++){
            temp[i] = text[i+begin];
        }
        return temp;
    }

    // This only implements some benchmark based on these descriptions
    //   https://forum.zcashcommunity.com/t/calculate-solutionsize/21042/2
    // and
    //   https://github.com/zcash/zcash/blob/996fccf267eedbd512619acc45e6d3c1aeabf3ab/src/crypto/equihash.cpp#L716
    function equihashTestN200K9() public returns (uint ret) {
        bytes memory scratch = new bytes(128);
        bytes memory scratch_ptr;
        assembly {
            scratch_ptr := add(scratch, 32)
        }
        Blake2b.Instance memory instance = Blake2b.init(hex"", 64);
        for (uint i = 0; i < 512; i++) {
            assembly {
                // This would be a 32-bit little endian number in Equihash
                mstore(scratch_ptr, i)
            }
            bytes memory hash = instance.finalize(getSlice(0, 3, scratch));
            assembly {
                ret := xor(ret, mload(add(hash, 32)))
                ret := xor(ret, mload(add(hash, 64)))
            }
            instance.reset(hex"", 64);
        }
    }

    function equihashTestN200K9(uint32[512] memory solutions) public returns (uint ret) {
        bytes memory scratch = new bytes(128);
        bytes memory scratch_ptr;
        assembly {
            scratch_ptr := add(scratch, 32)
        }
        Blake2b.Instance memory instance = Blake2b.init(hex"", 64);
        for (uint i = 0; i < 512; i++) {
            uint32 solution = solutions[i];
            assembly {
                // This would be a 32-bit little endian number in Equihash
                mstore(scratch_ptr, solution)
            }
            bytes memory hash = instance.finalize(getSlice(0, 3, scratch));
            assembly {
                ret := xor(ret, mload(add(hash, 32)))
                ret := xor(ret, mload(add(hash, 64)))
            }
            instance.reset(hex"", 64);
        }
        assert(ret == 0);
    }
}