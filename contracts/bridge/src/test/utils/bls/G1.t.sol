// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../test.sol";
import "../../../utils/bls12381/G1.sol";

contract G1Test is DSTest {
    using G1 for G1Point;

    function test_serialize() public {
        G1Point memory ng1 = G1.negativeP1();
        assertEq0(ng1.serialize(), hex'b7f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb');
    }

    function test_deserialize() public {
        bytes memory g1 = hex'0802ed05cd0f8b5a7e53915959a91d105f61c3e6a3483281a677de70456cbe80c4367d8bf1727dd7cbfb3c20dd2067db04563a80ae1e8c140e1a2a9681e390b6ce39c1920742c5cc2005a12b0ebf143d51e511feb83169624999b12e0700ae75';
        G1Point memory p = G1.deserialize(g1);
        G1Point memory e = G1Point(Fp(10649015950676493634620504066709069072, 43142456839214771564757806897632051492022874594939430609558377413119351744475), Fp(5764636087822793275149787389346681014, 93278493064807042609479760054494757548897347451312429333844174966115434278517));
        assertTrue(p.eq(e));

        bytes memory s = p.serialize();
        assertEq0(s, hex'8802ed05cd0f8b5a7e53915959a91d105f61c3e6a3483281a677de70456cbe80c4367d8bf1727dd7cbfb3c20dd2067db');
    }
}
