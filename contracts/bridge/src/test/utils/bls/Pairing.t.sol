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
import "../../../utils/bls12381/Pairing.sol";

contract PairingTest is DSTest {
    using G1 for G1Point;
    using G2 for G2Point;

    // Waiting for EIP-2537, using pytest first
    function testFail_pairing() public {
        G1Point memory p1 = G1Point({
            x: Fp({
                a: 0x000000000000000000000000000000000572cbea904d67468808c8eb50a9450c,
                b: 0x9721db309128012543902d0ac358a62ae28f75bb8f1c7c42c39a8c5529bf0f4e
            }),
            y: Fp({
                a: 0x00000000000000000000000000000000166a9d8cabc673a322fda673779d8e38,
                b: 0x22ba3ecb8670e461f73bb9021d5fd76a4c56d9d4cd16bd1bba86881979749d28
            })
        });
        G2Point memory p2 = G2Point({
            x: Fp2({
                c0: Fp({
                    a: 0x00000000000000000000000000000000122915c824a0857e2ee414a3dccb23ae,
                    b: 0x691ae54329781315a0c75df1c04d6d7a50a030fc866f09d516020ef82324afae
                }),
                c1: Fp({
                    a: 0x0000000000000000000000000000000009380275bbc8e5dcea7dc4dd7e0550ff,
                    b: 0x2ac480905396eda55062650f8d251c96eb480673937cc6d9d6a44aaa56ca66dc
                })
            }),
            y: Fp2({
                c0: Fp({
                    a: 0x000000000000000000000000000000000b21da7955969e61010c7a1abc1a6f01,
                    b: 0x36961d1e3b20b1a7326ac738fef5c721479dfd948b52fdf2455e44813ecfd892
                }),
                c1: Fp({
                    a: 0x0000000000000000000000000000000008f239ba329b3967fe48d718a36cfe5f,
                    b: 0x62a7e42e0bf1c1ed714150a166bfbd6bcf6b3b58b975b9edea56d53f23a0e849
                })
            })
        });

        G1Point memory p3 = G1Point({
            x: Fp({
                a: 0x0000000000000000000000000000000006e82f6da4520f85c5d27d8f329eccfa,
                b: 0x05944fd1096b20734c894966d12a9e2a9a9744529d7212d33883113a0cadb909
            }),
            y: Fp({
                a: 0x0000000000000000000000000000000017d81038f7d60bee9110d9c0d6d1102f,
                b: 0xe2d998c957f28e31ec284cc04134df8e47e8f82ff3af2e60a6d9688a4563477c
            })
        });
        G2Point memory p4 = G2Point({
            x: Fp2({
                c0: Fp({
                    a: 0x00000000000000000000000000000000024aa2b2f08f0a91260805272dc51051,
                    b: 0xc6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8
                }),
                c1: Fp({
                    a: 0x0000000000000000000000000000000013e02b6052719f607dacd3a088274f65,
                    b: 0x596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e
                })
            }),
            y: Fp2({
                c0: Fp({
                    a: 0x000000000000000000000000000000000d1b3cc2c7027888be51d9ef691d77bc,
                    b: 0xb679afda66c73f17f9ee3837a55024f78c71363275a75d75d86bab79f74782aa
                }),
                c1: Fp({
                    a: 0x0000000000000000000000000000000013fa4d4a0ad8b1ce186ed5061789213d,
                    b: 0x993923066dddaf1040bc3ff59f825c78df74f2d75467e25e0f55f8a00fa030ed
                })
            })
        });
        assertTrue(Pairing.pairing(p1, p2, p3, p4));
    }

    // Waiting for EIP-2537, using pytest first
    function testFail_map_to_curve_g2() public {
        Fp2 memory u = Fp2({
            c0: Fp({
                a: 18775604437575152535554998505519730575,
                b: 115072466216551891925297684016243411108613671708051101952807657705898295510609
            }),
            c1: Fp({
                a: 29472162847099851509296176051420522048,
                b: 46072049827588396192569751285311502150599650387549752789887495975066133463856
            })
        });
        G2Point memory p = G2.map_to_curve(u);
        G2Point memory e = G2Point({
            x: Fp2({
                c0: Fp({
                    a: 4771529762314222127652615089121941038,
                    b: 27991211403065569603352684119971037214426037576469694245936883398668617891910
                }),
                c1: Fp({
                    a: 30080785542710333248162673629657012530,
                    b: 89072159627938937202492029662165821541518499041498457381942243177506233030727
                })
            }),
            y: Fp2({
                c0: Fp({
                    a: 3670454082895649818712287944828681523,
                    b: 87027392047270186994386093104410885039350191291509970203406052811367506663056
                }),
                c1: Fp({
                    a: 19637128733164448367497774227388467363,
                    b: 43499303726590499707141535958176257445659542945154508867800912252439019330587
                })
            })
        });
        assertTrue(p.eq(e));

        u = Fp2({
            c0: Fp({
                a: 4717284846403363267710214151150143834,
                b: 103794126429544023686835943623993672013403721146269693672785425590589880355932
            }),
            c1: Fp({
                a: 10874805418113783588154913244247336343,
                b: 76227657196987847616772441647273971944444958450683914551013945823463274233240
            })
        });
        p = G2.map_to_curve(u);

        e = G2Point({
            x: Fp2({
                c0: Fp({
                    a: 28044168342354962397619671557118355045,
                    b: 11477871885792899863414284176319173889316051882270092461565711342729340971857
                }),
                c1: Fp({
                    a: 33810746708608338746746989326563518543,
                    b: 27522470688421824784295558219881144454610270081063217890081503548647262428531
                })
            }),
            y: Fp2({
                c0: Fp({
                    a: 27956380804122696774488833642545634722,
                    b: 94626203574507485982182169639263732031920832048727636677552953759883315819674
                }),
                c1: Fp({
                    a: 17800130916365306849252066136935891213,
                    b: 91105012306037853716949279172727735359903787426049279426521157288496314611660
                })
            })
        });

        assertTrue(p.eq(e));
    }
}
