// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "../../test.sol";
import "../../../spec/BEEFYCommitmentScheme.sol";
import "../../../truth/darwinia/DarwiniaLightClient.sol";

interface Hevm {
    function roll(uint) external;
}

contract DarwiniaLightClientTest is DSTest {
    bytes32 constant internal NETWORK = 0x4372616200000000000000000000000000000000000000000000000000000000;
    address constant internal BEEFY_SLASH_VALUT = 0x0f14341A7f464320319025540E8Fe48Ad0fe5aec;
    uint64  constant internal BEEFY_VALIDATOR_SET_ID = 0;
    uint32  constant internal BEEFY_VALIDATOR_SET_LEN = 100;
    bytes32 constant internal BEEFY_VALIDATOR_SET_ROOT = 0x2941c5edce62f9a4acb16a1dff34354992edd3453944535d783dc952f1e09cb4;

    Hevm internal hevm = Hevm(HEVM_ADDRESS);
    DarwiniaLightClient public lightclient;
    address public self;

    receive() external payable {}

    function get_power_of_two_ceil(uint256 x) internal pure returns (uint256) {
        if (x <= 1) return 1;
        else if (x == 2) return 2;
        else return 2 * get_power_of_two_ceil((x + 1) / 2);
    }

    function setUp() public {
        lightclient = new DarwiniaLightClient(
            NETWORK,
            BEEFY_SLASH_VALUT,
            BEEFY_VALIDATOR_SET_ID,
            BEEFY_VALIDATOR_SET_LEN,
            BEEFY_VALIDATOR_SET_ROOT
        );
        self = address(this);
    }

    function test_new_signature_commitment() public {
        perform_phase_1();
    }

    function testFail_complete_signature_commitment() public {
        perform_phase_1();
        hevm.roll(13);
        perform_phase_2();
    }

    function perform_phase_1() internal {
        bytes32 commitmentHash = 0x09e680ec06b1c200da56a2e15b831d8dff6616430c05a2ceaae504ae20b46d7d;
        uint256 validatorClaimsBitfield = 1044487351351913501414451380084;
        bytes32[] memory p = new bytes32[](7);
        p[0] = 0xd0d3f7fd7ad7b0d828d241478349d8c7412cfe4cf2f1a17e55195ba7e01355ef;
        p[1] = 0x6d2421af32f1dbec4cc59a11d3d18f467cc189486f79b1cc63499ae116c4c73f;
        p[2] = 0x76119001ed628af027c8930eef7c87196bae49d4f7dfd2d02e242b5acce53e38;
        p[3] = 0x2131f3ab6f1373f6accef711d1d5fae80f0f922b169ace79cef610e26647a23b;
        p[4] = 0x3704a8de1d2845173e2a93ac6b2f1c09e83872cc56de88390fd6e31c7d416d3b;
        p[5] = 0x5a84e69a1c0b85576cc3e78a8f3537ac56e12fdc833ce51b635a30399636240b;
        p[6] = 0x1c59d9ccec531dc76cdad960db5bd2114c755b39da083ac0393798c5ff1ef34e;
        DarwiniaLightClient.Signature memory signature = DarwiniaLightClient.Signature(
            0xea1ce2280585a497543ebe82c2dbc84e36e7ea073a13890bc6d87e37b0056422,
            0x51d38a842c0eb0a8587c6acd7cc938100975e9d708b79f8a164aac23f3eb79f7
        );
        DarwiniaLightClient.CommitmentSingleProof memory proof = DarwiniaLightClient.CommitmentSingleProof(
            39,
            0x54c4310212f50bE3fa81Cc91C9F71e843E780f49,
            p,
            signature
        );
        uint32 id = lightclient.newSignatureCommitment{value: 4 ether}(
            commitmentHash,
            validatorClaimsBitfield,
            proof
            );
        assertEq(uint256(id), 0);
    }

    function perform_phase_2() internal {
        BEEFYCommitmentScheme.NextValidatorSet memory set = BEEFYCommitmentScheme.NextValidatorSet(1, 3, 0x92622f8520ac4c57e72783387099b2bc696523782c5e5fae137faff102268e07);
        BEEFYCommitmentScheme.Payload memory payload = BEEFYCommitmentScheme.Payload(
            0x4372616200000000000000000000000000000000000000000000000000000000,
            0x2c0a2fc1108ee004f48eec805ed60e9d7c364106389f67bf7667a36769a42eb6,
            0xaeaa48e8dbb7563f0a7037a924a3361de9c70b4871153f33b22dc641dcc66cff,
            set
        );
        BEEFYCommitmentScheme.Commitment memory commitment = BEEFYCommitmentScheme.Commitment(
            payload,
            12,
            0
        );
        bytes32[] memory decommitments = new bytes32[](46);
        decommitments[0] = 0x484f623d6cb520241fd2316e460c63a2648f15e6b2997860ed4908340e49f47e;
        decommitments[1] = 0xa55df66d11cea39ea69435790c0e96a98e707dbcd107e76d3cb183ec09b5e79b;
        decommitments[2] = 0x7c2d96f0234460d5d41cd15110fd9590888a88ef68fcc8b6839d085fb8af3052;
        decommitments[3] = 0xc4cebfc42beef2c4034e2717d1a8320214670376038baee4c6ac218a4c0f8c43;
        decommitments[4] = 0x3ef4dbde57ce12a93fc79d35b5e2ddc211b9df32d6d26d127fc0d1a3730aff59;
        decommitments[5] = 0x4f3517e3e0bcbbf72590963fe8a53ce90f027e36434df934e1deca333c43f818;
        decommitments[6] = 0x05f272df7f48c7e44f7a600b528facab132d6c14afb8ba0ab0ba3a9cf74fcef3;
        decommitments[7] = 0x0eda5fd83a358b666f36498d03a77a5f7dfaee04f09892356c425b622b2a2f13;
        decommitments[8] = 0x8107fa7aec297cce3d698fcdb036fc5727d6b66f0ea0e61cad9ab85a3e69896a;
        decommitments[9] = 0xa5d595fa24aa14896e96dcb10834eccacd545734e5f85ad6207c48a0d78cd74a;
        decommitments[10] = 0x3f67e97092e6106afa5f2413f412d0490b65688e6f3bfbc74eed99511ef06b29;
        decommitments[11] = 0xd851aee17f2627951875e2a3fee11842a896861df1c3dec7cff2344bfdffb906;
        decommitments[12] = 0xa0a6d708bfeb4d7231a5c803ddf19512789cf65cf04d98a8d22888abb9f48afe;
        decommitments[13] = 0xe2065860a73bbef1c459b054c1002835d8c05dafe2b2beae2b768f6153921d9c;
        decommitments[14] = 0x63bded933fde3a14d98df8ed33db48d96319d35ac09f9228df19eeeca54f3b57;
        decommitments[15] = 0x0b1c4d325afcdc1952422de14e3ac318d82d85a35de1217cba073ed217460fa9;
        decommitments[16] = 0xc6baf603ac8d96c67ce3e9deac5b5d9fc029d83ae2f7191d24e239600425b5ba;
        decommitments[17] = 0x920bb528af87c8bd42dfaa5f33e383b10541cd1267015de503b714cbf8cb7175;
        decommitments[18] = 0xc11b132b1f4f8d870e80c5b785bd3ab00b5071d94b04db02ec0efdc0a71a3f49;
        decommitments[19] = 0xe346c65593a4bcbf62d400abf8fc58865e9cac644979f521fae1ddc0b5bb7756;
        decommitments[20] = 0x66d39fe489d5436609d9f6c978ebc56a9680fd859f8de1e270c8e70f198ebf05;
        decommitments[21] = 0x278da5c4fac35bd7c32c7758583534984445a676468c8f1df65cd3c2fb0b93c3;
        decommitments[22] = 0x5ed962cea1d8800bd816cfc5f755c69102eca85c5311667537830464ccbf4bc4;
        decommitments[23] = 0x0ee771d1e525a255c309ddca738a0f2f242a9b5ff976b667cf064722905d92c9;
        decommitments[24] = 0x4ce649319e895dd4a7d71fabbab900ca86614b27cea84815656cca5155a77830;
        decommitments[25] = 0xab212981d9483f86d7ba12b1a3609c9995a7a2409cd8ed78d1603f7f9fbc4942;
        decommitments[26] = 0xe6ac1a8595e326f4b9fa6f17371a6528210c391a7adba62eed0f38b1a37011fa;
        decommitments[27] = 0xc2b3201ad8f9b06d882cd12d7425bad8f5577f81345a7dc96c4e78f6f3692f2b;
        decommitments[28] = 0x7e3477bc8d789b1f13490207aacf6b05a1f21bfe15d01964c4bcb1361d5af068;
        decommitments[29] = 0xe055c48ffa326dbc7de560aaef6c77128e771c76c405505cb5b447c3820d9032;
        decommitments[30] = 0x48a49aa532ef00e3709125fd1465d4ea903e89e3cd3e8f06a2229c1173fc2fc2;
        decommitments[31] = 0xe64248bdf5b721c6796fcb75e1afe3bb15ae2543eada094d576512f38d640b73;
        decommitments[32] = 0x70e7c7253f012955e620316b1ac7dfcf0197fd125b2fdec308c10eb977f772e0;
        decommitments[33] = 0x6d2421af32f1dbec4cc59a11d3d18f467cc189486f79b1cc63499ae116c4c73f;
        decommitments[34] = 0xb960757f201f6f8a774b4178015f87afa0fd793259e8ad4c149929a77a2b1986;
        decommitments[35] = 0xf728e48d1cef822a216ead28fcc2c8f4f66f74ae96f19761cbb2ce0ea89d6a10;
        decommitments[36] = 0x59f06bf8e4b6ff7eaf4f8e9b355ddc3473cde8ea8ebffe62b6c103280115ab09;
        decommitments[37] = 0xdec1d0e2dfbde215e8e943639540bb6c476c38b9969884bfb11640a7126dade3;
        decommitments[38] = 0x940f4677df688005ff256120a86d431f96c926f884135e28f06041c5aa48194b;
        decommitments[39] = 0xb7211c51ea56e816a877d83f7014614fb3f94d9c3e83e7af314a27537daf9452;
        decommitments[40] = 0x8e96b4ecb3cf6029b058a84973b124fe9774a510e856b5d6b15c19f2d2e8a5dc;
        decommitments[41] = 0x76119001ed628af027c8930eef7c87196bae49d4f7dfd2d02e242b5acce53e38;
        decommitments[42] = 0xefba0feb4e3f69cbc4a666e14ea35b7197ce06a1c08678cb48151c6903c9eb88;
        decommitments[43] = 0xd0c0f947e507b0e5866d07fa3b91caece83e20a3158d51c5aa52bfa04d301777;
        decommitments[44] = 0xd16b5b6b5784d0fcd72c34ff86d6722808e1fed2bc05706119aac9adf6f5d813;
        decommitments[45] = 0xecd6778edd1e0c9e481d041745cb95782313ceb25df854e1731456ba9b3c36a8;
        DarwiniaLightClient.Signature[] memory sigs = new DarwiniaLightClient.Signature[](25);
        sigs[0] = DarwiniaLightClient.Signature(
            0xf22b0e435bb8646a69dee6b9826c4cbfa76bd25a0c839a349efc137a4bc17ca6,
            0xaca0bf37998ac4b2ec0b2d965213f61bc45225c8bb18a3a15d0c0eed698a5451
        );
        sigs[1] = DarwiniaLightClient.Signature(
            0x3512fa6b039aa372b8a33b9ef33c368990fe18d36582ca023c9ed9ee1e452abf,
            0xcee616a667e99f8e6864b2c56045f3739bd861ac6bd33d811c99cd9b21edb956
        );
        sigs[2] = DarwiniaLightClient.Signature (
            0x1de87d64d008d57f2d9ca800cc92f8ef2a2d3cba8cd1f9ffb5327e6fd0c01e08,
            0x3dc467c35e114cc4a07a89016e1908e2c05526b24e7a7be5b1addbe345ae8742
        );
        sigs[3] = DarwiniaLightClient.Signature (
            0x75b706fb842155c444d1d6c182379c8db1374c7dd5472600966c49debe24bff4,
            0x0ed9d7f9babdf21190820467eb39d511117c83bd22847119842b620e5e48c801
        );
        sigs[4] = DarwiniaLightClient.Signature (
            0x1c48f2e65efbd9ada94ef82728ec86f404180233e78ea50dc738c45af50e87af,
            0xdf5a279fe26ce21a0529b06deb92290509c6bce5a07d4814668bf3def5692c97
        );
        sigs[5] = DarwiniaLightClient.Signature (
            0xe3437f0123911772b067853fe42db8c538392ac7aaae153b454e7e816bec6a4a,
            0xd7492a624a80fc28d4cc4db1d1f054c7a8518be48c1a8d69008cae14d34bb8bf
        );
        sigs[6] = DarwiniaLightClient.Signature (
            0x8701bb7ca27b65bba895e6814514e58f69d6f91327efdc89fccb7198e02271e7,
            0xde691f378292d635e42580e8c341d51756f7e6c968a6dd0c8f4a55026309dd1c
        );
        sigs[7] = DarwiniaLightClient.Signature (
            0xe5981122bea084fb22626f2cdc82d516feb745ab283ff7480fd38a6ca3902c1b,
            0x1a3a103676f4cf6806d9848c196d0e7ddabd8fcfe2d650e2e8c83284b6ca908b
        );
        sigs[8] = DarwiniaLightClient.Signature (
            0x45b934c32c720ea79341b6d5471ff98c10a968b235d0eb822b58c151abb90629,
            0xfa7e08be95afb2a045ed6e2ace2d838245b74a54ec588f80f7b1abda8004227f
        );
        sigs[9] = DarwiniaLightClient.Signature (
            0x13d9cf38201e01e56c6d544f213c30b72180aa8e5c2b8b49ce2e050a3ab7dd80,
            0x315551816afbc4ceb27c9a725ffa31f8b2cef0ffa58e4f267c787dc80aebf6e4
        );
        sigs[10] = DarwiniaLightClient.Signature (
            0x9716f481dd41bc91ea3db23f7e332aae5696bca37ddf97a02a969212084001c6,
            0x6b55fc84748208ae30c4d2bcbdcda8ee0cbd40f8146e45d95d354ef691b511a3
        );
        sigs[11] = DarwiniaLightClient.Signature (
            0xc940111fe89ee3129d5f41599438438e7bc65a1a7d1650e0c392dec7aefbe466,
            0xbb4d28518c2f1661a8f07c988025ccc7de669d6eae970813a05368194f3f409b
        );
        sigs[12] = DarwiniaLightClient.Signature (
            0xcc15cd30fbb605843fe974a26f6c118333539186397399ab0447ead27df7e364,
            0x05fa84287a0e603708fb183fc0bbe5e6b8def2727e80fcf229cb9fa18bf46695
        );
        sigs[13] = DarwiniaLightClient.Signature (
            0x6bbabf81365eadf404cb1bc7cbdd5faac44f5e1bc0addddc1122fd9e1001a95b,
            0xb6a996ec434ba8b8b080fdac1300609714432e47e68b5778f7a499e903f23e24
        );
        sigs[14] = DarwiniaLightClient.Signature (
            0x5fcd4eb8e847c3a6ab5ff6ae07e6fdb4d43d9fc45192e945258c1863c960601d,
            0x6c3cedc14ffa0fc5370b0fe648f30400de2a160e85f764858a6c08c11db39fdd
        );
        sigs[15] = DarwiniaLightClient.Signature (
            0xcb4d98eb1877d0010c6c087d293946fe110396b6ae75c333a51bf3ccebdcc5ca,
            0xa062a1c13c70190413e2cf2e9c9841d6788f4f80e0e7d03aafda7f0f513dc298
        );
        sigs[16] = DarwiniaLightClient.Signature (
            0x5aee63334ac65af4b4f3fdb8beb847b909f8d458b2cc6e30d2d25f22dbf49cfd,
            0x6dfc36eb2559394ce7fc985a02af75412fc92de6d20a4bd86f4e71202c6ec531
        );
        sigs[17] = DarwiniaLightClient.Signature (
            0x2fff64c1a58c64d41a723b5987262c30d403786f0f306549e08578551243651f,
            0xe634b943d465fe72bd6c9d74ff7fd5f9f9aa77f3de46762e6f226253546400f9
        );
        sigs[18] = DarwiniaLightClient.Signature (
            0xb8d24f94c0afaef80cfef820733843122eaef555a55cbab5b6b873b2fb10fcd5,
            0x08f3bb37f7931f349993d30842b10d372178de402360b9191b895b88ab67733e
        );
        sigs[19] = DarwiniaLightClient.Signature (
            0xeec196f462b099a994f446301f8248f5f03f782d60c03d080a1515d7358289d8,
            0x9ce39c9ae6451fb415afba3715e06a4bb178ee2ed02506a23256bfc38e522a04
        );
        sigs[20] = DarwiniaLightClient.Signature (
            0x0f06aafbc9a720ae486b98e293a3ed28faa1a94c78178b3802e272006385ad36,
            0x088b45a018ce6b88b6d3a27cbe3956e1fdb3495455f6e63c0ce6a89ac13437a8
        );
        sigs[21] = DarwiniaLightClient.Signature (
            0x75f612ba40e28e5985a515b44db92f1f631739d4573c6723a33954a0aeb33e50,
            0x71f8e0ff6d10d646fc233db571819c254730299d64ebdd76a602f07fca185ece
        );
        sigs[22] = DarwiniaLightClient.Signature (
            0xb175f36db3858d4c92de679adde764af0749e3a875bb91d1a6240aefd308f8fa,
            0xc673c9112499410679f85e460629d04c77a876727af4867a43036b60b8b201d7
        );
        sigs[23] = DarwiniaLightClient.Signature (
            0x4bf41c845e4f78f9ad37939576773af50216a103024cdfb7db9253234a066014,
            0x2d9e8877f47c7825e074419e1f46a843e753b644d2ac8ef83e744d813704c803
        );
        sigs[24] = DarwiniaLightClient.Signature (
            0xd61fd2be509225e88101bb8cb22aca43ade6fcf18e0905aff9c62b23e4fe23d9,
            0x03b349bed9cffd29af12a89bfb4f1297ef453eaed24d40a557771822ca1de700
        );
        DarwiniaLightClient.CommitmentMultiProof memory proof = DarwiniaLightClient.CommitmentMultiProof(
            7,
            0x605957504b494742403d393634322f2d2b28261d1a130f0a0800000000000000,
            decommitments,
            sigs
        );
        lightclient.completeSignatureCommitment(
            0,
            commitment,
            proof
        );
    }

    function test_get_power_of_two_ceil() public {
        assertEq(get_power_of_two_ceil(100), 128);
    }
}
