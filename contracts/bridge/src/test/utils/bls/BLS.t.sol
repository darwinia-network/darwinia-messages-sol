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

import "../../test.sol";
import "../../../utils/bls12381/BLS.sol";

contract BLSTest is DSTest {
    using FP2 for Fp2;
    using G2 for G2Point;
    using Bytes for bytes;

    // Waiting for EIP-2537, using pytest first
    function testFail_bls_pairing_check() public {
        G1Point memory key_point = G1Point({
            x: Fp({
                a: 26627434292402230803163858128455585914,
                b: 48634982462735808718895679799386069894578484234911513006586203230657604913836
            }),
            y: Fp({
                a: 14856821957515554002181972608605741852,
                b: 25416517180090498104081766963124621484473644952830749638673217029993138557934
            })
        });

        G2Point memory msg_hash = G2Point({
            x: Fp2({
                c0: Fp({
                    a: 440249405659325969529968607583110888,
                    b: 8287011717308296271484778081523466175176315688302323040678920909110172052883
                }),
                c1: Fp({
                    a: 24020475586686358824048391002731990219,
                    b: 70759422662205377238812159328664300970743143867490115357570028073099023505250
                })
            }),
            y: Fp2({
                c0: Fp({
                    a: 1386680577929784893551049599873021837,
                    b: 27514265084368602307416113347133013730132425074985547665978961921775804054489
                }),
                c1: Fp({
                    a: 29803136074860227348525644626316084686,
                    b: 27012386664933262761093142209614962474294368617355502707705554906602519553290
                })
            })
        });

        G2Point memory sig_point = G2Point({
            x: Fp2({
                c0: Fp({
                    a: 21119453716311089298661719635637843530,
                    b: 70301835649641000901160347641203690598647566398903256239764622874509047347076
                }),
                c1: Fp({
                    a: 5920268386667820052614231331002922384,
                    b: 60500088921229408394397585038144717166868811544401247695705260970207586478821
                })
            }),
            y: Fp2({
                c0: Fp({
                    a: 31295527203677419532351065800929160364,
                    b: 24349246807094560350851965287716353817621039716553532902762100173406977412078
                }),
                c1: Fp({
                    a: 6584272192056904658154384891933189686,
                    b: 91936439523527484860611422496069315700431954270715891103668743441226387088003
                })
            })
        });

        assertTrue(BLS.bls_pairing_check(key_point, msg_hash, sig_point));
    }

    function test_expand_message_xmd() public {
        bytes32 m = 0x3a896ca4b5db102b9dfd47528b06220a91bd12461dcc86793ce2d591f41ea4f8;
        assertEq0(BLS.expand_message_xmd(m), hex'96b5f290540c141d2952c2b57c8c48b949c2b8aae625a3a5bab1e279455a3ffdeda87d153bcbe3a6badec0451f0cb18499291952bfe663b37c1ab5d07d72599a18bfd073699d6e75dee027d6607fa9712f944f1bee7faa631a820baf583c04b9fe9d7bc4f792cbcb1771ad9326c8e83222b78e7df6d7ac5be93734bf62182fe3b0da1c878cf716c890feb30d52b646abaad7f897f32a21cf26e3dd6a7cd16ae1a9addc303ad34d37d20f4662c0a51738d1052a55e451d65ef7710d954b29efec7ca24d1a527280adfce3cde1354f3a49b7e1d2dd821d22aff0ea91acf773d724e954e63f03ad942a07d503d7b6d2e9914176d77964f7dd4e3ab335d5608b61c3');
    }

    function test_hash_to_field_fq2() public {
        bytes32 m = 0x3a896ca4b5db102b9dfd47528b06220a91bd12461dcc86793ce2d591f41ea4f8;
        Fp2[2] memory e = [
            Fp2({
                c0: Fp({
                    a: 18775604437575152535554998505519730575,
                    b: 115072466216551891925297684016243411108613671708051101952807657705898295510609
                }),
                c1: Fp({
                    a: 29472162847099851509296176051420522048,
                    b: 46072049827588396192569751285311502150599650387549752789887495975066133463856
                })
            }),
            Fp2({
                c0: Fp({
                    a: 4717284846403363267710214151150143834,
                    b: 103794126429544023686835943623993672013403721146269693672785425590589880355932
                }),
                c1: Fp({
                    a: 10874805418113783588154913244247336343,
                    b: 76227657196987847616772441647273971944444958450683914551013945823463274233240
                })
            })
        ];
        Fp2[2] memory u = BLS.hash_to_field_fq2(m);
        assertTrue(u[0].eq(e[0]));
        assertTrue(u[1].eq(e[1]));
    }

    // Waiting for EIP-2537, using pytest first
    function testFail_hash_to_curve_g2() public {
        bytes32 m = 0x3a896ca4b5db102b9dfd47528b06220a91bd12461dcc86793ce2d591f41ea4f8;

        G2Point memory e = G2Point({
            x: Fp2({
                c0: Fp({
                    a: 440249405659325969529968607583110888,
                    b: 8287011717308296271484778081523466175176315688302323040678920909110172052883
                }),
                c1: Fp({
                    a: 24020475586686358824048391002731990219,
                    b: 70759422662205377238812159328664300970743143867490115357570028073099023505250
                })
            }),
            y: Fp2({
                c0: Fp({
                    a: 1386680577929784893551049599873021837,
                    b: 27514265084368602307416113347133013730132425074985547665978961921775804054489
                }),
                c1: Fp({
                    a: 29803136074860227348525644626316084686,
                    b: 27012386664933262761093142209614962474294368617355502707705554906602519553290
                })
            })
        });

        G2Point memory p = BLS.hash_to_curve_g2(m);

        assertTrue(p.eq(e));
    }

    function test_slice_to_uint() public {
        bytes memory f = hex'1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab';
        uint pa = f.slice_to_uint(0, 16);
        assertEq(pa, 0x1a0111ea397fe69a4b1ba7b6434bacd7);
        uint pb = f.slice_to_uint(16, 48);
        assertEq(pb, 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab);
    }
}
