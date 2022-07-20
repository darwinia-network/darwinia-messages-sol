// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

struct Fp {
    uint a;
    uint b;
}

library FP {
   function eq(Fp memory x, Fp memory y) internal pure returns (bool) {
       return (x.a == y.a && x.b == y.b);
   }
}
