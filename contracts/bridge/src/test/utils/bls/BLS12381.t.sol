// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../../test.sol";
import {B12_381Lib, B12} from "../../../utils/bls/BLS12381.sol";

contract BLS12381Test is DSTest {

    function test_pairing() public {
        B12.G1Point memory g1 = B12.G1Point({
            X: B12.Fp({
                a: 0x000000000000000000000000000000000572cbea904d67468808c8eb50a9450c,
                b: 0x9721db309128012543902d0ac358a62ae28f75bb8f1c7c42c39a8c5529bf0f4e
            }),
            Y: B12.Fp({
                a: 0x00000000000000000000000000000000166a9d8cabc673a322fda673779d8e38,
                b: 0x22ba3ecb8670e461f73bb9021d5fd76a4c56d9d4cd16bd1bba86881979749d28
            })
        });
        B12.G2Point memory g2 = B12.G2Point({
            X: B12.Fp2({
                a: B12.Fp({
                    a: 0x00000000000000000000000000000000122915c824a0857e2ee414a3dccb23ae,
                    b: 0x691ae54329781315a0c75df1c04d6d7a50a030fc866f09d516020ef82324afae
                }),
                b: B12.Fp({
                    a: 0x0000000000000000000000000000000009380275bbc8e5dcea7dc4dd7e0550ff,
                    b: 0x2ac480905396eda55062650f8d251c96eb480673937cc6d9d6a44aaa56ca66dc
                })
            }),
            Y: B12.Fp2({
                a: B12.Fp({
                    a: 0x000000000000000000000000000000000b21da7955969e61010c7a1abc1a6f01,
                    b: 0x36961d1e3b20b1a7326ac738fef5c721479dfd948b52fdf2455e44813ecfd892
                }),
                b: B12.Fp({
                    a: 0x0000000000000000000000000000000008f239ba329b3967fe48d718a36cfe5f,
                    b: 0x62a7e42e0bf1c1ed714150a166bfbd6bcf6b3b58b975b9edea56d53f23a0e849
                })
            })
        });

        B12.G1Point memory g3 = B12.G1Point({
            X: B12.Fp({
                a: 0x0000000000000000000000000000000006e82f6da4520f85c5d27d8f329eccfa,
                b: 0x05944fd1096b20734c894966d12a9e2a9a9744529d7212d33883113a0cadb909
            }),
            Y: B12.Fp({
                a: 0x0000000000000000000000000000000017d81038f7d60bee9110d9c0d6d1102f,
                b: 0xe2d998c957f28e31ec284cc04134df8e47e8f82ff3af2e60a6d9688a4563477c
            })
        });
        B12.G2Point memory g4 = B12.G2Point({
            X: B12.Fp2({
                a: B12.Fp({
                    a: 0x00000000000000000000000000000000024aa2b2f08f0a91260805272dc51051,
                    b: 0xc6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8
                }),
                b: B12.Fp({
                    a: 0x0000000000000000000000000000000013e02b6052719f607dacd3a088274f65,
                    b: 0x596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e
                })
            }),
            Y: B12.Fp2({
                a: B12.Fp({
                    a: 0x000000000000000000000000000000000d1b3cc2c7027888be51d9ef691d77bc,
                    b: 0xb679afda66c73f17f9ee3837a55024f78c71363275a75d75d86bab79f74782aa
                }),
                b: B12.Fp({
                    a: 0x0000000000000000000000000000000013fa4d4a0ad8b1ce186ed5061789213d,
                    b: 0x993923066dddaf1040bc3ff59f825c78df74f2d75467e25e0f55f8a00fa030ed
                })
            })
        });
        B12.PairingArg[] memory args = new B12.PairingArg[](2);
        args[0] = B12.PairingArg(g1, g2);
        args[1] = B12.PairingArg(g3, g4);
        assertTrue(B12_381Lib.pairing(args));
    }
}
