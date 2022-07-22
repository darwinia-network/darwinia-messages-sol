// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../test.sol";
import "../../../utils/bls12381/G1.sol";

contract FPTest is DSTest {
    using G1 for G1Point;

    function test_serialize() public {
        G1Point memory ng1 = G1.negativeP1();
        assertEq0(ng1.serialize(), hex'b7f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb');
    }
}
