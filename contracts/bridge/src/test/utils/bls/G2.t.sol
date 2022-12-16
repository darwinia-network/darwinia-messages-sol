// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;
pragma abicoder v2;

import "../../test.sol";
import "../../../utils/bls12381/G2.sol";

contract G2Test is DSTest {
    using G2 for G2Point;

    function test_deserialize() public {
        bytes memory g2 = hex'016d4c6b8cd9345709d083ea4c4188c8b91800a3a1caafc06ce2f906c1f76b60cb34dbeb7bb502507bb4075b61a965a60c26952837b1f30e3725cffadd55033ec62f9360659c68188b7192f4e641f39bc15a8b8847e942c5218f7eae57ed215e0a6bb39fd7b06d281beffb5f467375531c51fcd6806da645632f411647fc311789f21c8f23b6a07c591ecfe2defe5ef00a900e323870437512d5fd969791096cd9d9447a9a93d1820c5dd4b2788481415083449cfc94e7da3eb1e808f1e9afa3';
        G2Point memory p = G2.deserialize(g2);
        G2Point memory e = G2Point(
            Fp2(
                Fp(16151068495437561801725848888167170878, 89642002987100070632632767689389170464052999910370829768562836973736617124190),
                Fp(1896738337498964084125711630950566088, 83720285728968929179342853752928184368010530093097347811765285655377967932838)
            ),
            Fp2(
                Fp(14040258638087629544122117905280207212, 98535766579769692703063581988100677270816044198382309708122405093706635521955),
                Fp(13851498937061842235997261836865205587, 12809619395611566517490361690486986994655575793052973210605792449286148873968)
            )
        );
        assertTrue(p.eq(e));

        bytes memory s = p.serialize();
        assertEq0(s, hex'816d4c6b8cd9345709d083ea4c4188c8b91800a3a1caafc06ce2f906c1f76b60cb34dbeb7bb502507bb4075b61a965a60c26952837b1f30e3725cffadd55033ec62f9360659c68188b7192f4e641f39bc15a8b8847e942c5218f7eae57ed215e');
    }
}
