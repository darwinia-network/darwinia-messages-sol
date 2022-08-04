// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../test.sol";
import "../../../utils/bls12381/Fp.sol";

contract FPTest is DSTest {
    using FP for Fp;

    function test_serialize() public {
        Fp memory q = FP.q();
        assertEq0(q.serialize(), hex'1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab');
    }

    function test_is_valid() public {
        Fp memory q = FP.q();
        assertTrue(!q.is_valid());
    }

    function test_is_zero() public {
        Fp memory q = FP.q();
        Fp memory zero = FP.zero();
        assertTrue(zero.is_zero());
        assertTrue(!q.is_zero());
    }
}
