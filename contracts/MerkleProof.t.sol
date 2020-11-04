pragma solidity >=0.5.0 <0.6.0;

import "./ds-test/test.sol";

import "./MerkleProof.sol";
pragma experimental ABIEncoderV2;

contract MerkleProofTest is MerkleProof, DSTest {
    function setUp() public {}

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

    function testSimplePairVerifyProof() public returns(bool) {

        bytes32 root = hex"36d59226dcf98198b07207ee154ebea246a687d8c11191f35b475e7a63f9e5b4";
        bytes[] memory proof = new bytes[](1);
        proof[0] = hex"44646f00";
        bytes[] memory keys = new bytes[](1);
        keys[0] = hex"646f";
        bytes[] memory values = new bytes[](1);
        values[0] = hex"76657262";
        bool res = verify(root, proof, keys, values);
        assertTrue(res);
    }

    function testPairVerifyProof() public returns(bool) {

        bytes32 root = hex"e24f300814d2ddbb2a6ba465cdc2d31004aee7741d0a4964b879f25053b2ed48";
        bytes[] memory merkleProof = new bytes[](3);
        merkleProof[0] = hex"c4646f4000107665726200";
        merkleProof[1] = hex"c107400014707570707900";
        merkleProof[2] = hex"410500";

        bytes[] memory keys = new bytes[](1);
        keys[0] = hex"646f6765";
        bytes[] memory values = new bytes[](1);
        values[0] = hex"0000000000000000000000000000000000000000000000000000000000000000";
        bool res = verify(root, merkleProof, keys, values);
        assertTrue(res);
    }

    function testPairsVerifyProofBlake2b() public returns(bool) {

        bytes32 root = hex"8b5b6ad240751b4af62bf0e939731564bfb41b9bfbe01e32e00154eae31cfe43";
        bytes[] memory merkleProof = new bytes[](1);
        merkleProof[0] = hex"810006000c420200144203080405";

        bytes[] memory keys = new bytes[](1);
        keys[0] = hex"0102";
        bytes[] memory values = new bytes[](1);
        values[0] = hex"01";
        bool res = verify(root, merkleProof, keys, values);
        assertTrue(res);
    }

    // function testPairVerifyProofBlake2b() public {
    //         bytes32 root
    //      = hex"2a6b9a056f6336ab2417eedcc455a18abd01517c0a4a9adb958699eed84d8b4b";
    //     bytes[] memory merkleProof = new bytes[](4);
    //     merkleProof[0] = hex"80490c80b0eadd9230e584b47e00b7cf8e1f927cee0d50485a3c676a11b384ead2bf36ee80bc95ec1b2225e13c653524cb1ff8714173c780ef580581ff66c9604e7fb536c380fda12eddcd0a2e270526fc0037de9da9dcda5c99049e1f74a520c5cbd85db96b8064d657470e1a79e65884b81f1085d11308fd3182d566ffe2b419413ce0495e1980a60aa390511c25e70c1b029d951ef2fd0255b8a3fc3580bed4c4b2fa31789781";
    //     merkleProof[1] = hex"80fffb80fbd313c51ce7764956f81ef87ff3ebc489b3232cfed8fef9a8434b7414d6f7c880760034d4c3469cab2f0c3c5417980460d295fd8b49cff262a4afb8290c38a57b80150154959b53b033e56db6cb65aa2fedca9dd0071f25eae7ba262841eaf0dbbd807adb48ce7c7686a6b1f726eca635aecf163fcb1ec47f7cacec194be9f340d7b1805c72f25b1b6304d16667e2766fa1a906cb081788eb4502787df7c3597412b17b802d39230527f49cf88fbdd4bf7e3dbcd564218ea2c20751ee4e4e24ecb44989a5800eb754c27d6302344f80fc4f785eae09c7c6acf58ee0ebddbd2f1755eb37a7de806246fab7082d42447ff6a3e4653cb8c2427408eae98af0c40f9c636b972f91548034260342013b628b1a3409a53683bd72866b974fc4bb1e2db0b50c4abd88df0680468f4c745f210c713c8eee6d4bc90e15ac9e708974088d1bf5e01db7fc0781bb809d5adec17d1f91d73f0a631ffe17af9dae7007f69f11bc4d46ca2b9777a921688090e4fe33f4b3a304329c97d1ee3cb8240585cd8c4a1da47f79423a1d91dd1d7180a7a88069a098bb5725ce52c5cf702bed3b1f6f134a69f585d43ab497995fd35280cbcdf9de3ff34d475ef3dad95c4217e6ee4a1e40897550291620d88e1a77c2bd806440a709fcb73133283c13668a87da24982f6b61060d169deb5a43532b553318";
    //     merkleProof[2] = hex"5f00d41e5e16056765bc8461851072c9d74505240000000000000080e36a09000000000200000001000000000000000000000000000200000002000000000000ca9a3b00000000020000000300000000030e017b1e76c223d1fa5972b6e3706100bb8ddffb0aeafaf0200822520118a87e00000300000003000e017b1e76c223d1fa5972b6e3706100bb8ddffb0aeafaf0200822520118a87ef0a4b9550b000000000000000000000000000300000003020d584a4cbbfd9a4878d816512894e65918e54fae13df39a6f520fc90caea2fb00e017b1e76c223d1fa5972b6e3706100bb8ddffb0aeafaf0200822520118a87ef0a4b9550b00000000000000000000000000030000000e060017640700000000000000000000000000000300000003045a9ae1e0730536617c67ca727de00d4d197eb6afa03ac0b4ecaa097eb87813d6c005d9010000000000000000000000000000030000000000c0769f0b00000000000000";
    //     merkleProof[3] = hex"9eaa394eea5630e07c48ae0c9558cef7098d585f0a98fdbe9ce6c55837576c60c7af3850100900000080a4adb17d600ad56fb70d03060fc70c9636b53bac26f3d45a525461b3d9fbd8ea80950043f807c1289b7636f6a759abc843caa0f2da40d133ff2fe8821926fd7d93803520a0cde9eee6081349f75cb2771853207aa1b0136c1303677c394d3b2de74880dc4f83e9b8934c4dcffc1d12f846210d0b469982edff3c19c3e89246d9f9b27a705f09cce9c888469bb1a0dceaa129672ef8284820706f6c6b61646f74";

    //     bytes[] memory keys = new bytes[](1);
    //     keys[0] = hex"26aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7";
    //     bytes[] memory values = new bytes[](1);
    //     values[0] = hex"240000000000000080e36a09000000000200000001000000000000000000000000000200000002000000000000ca9a3b00000000020000000300000000030e017b1e76c223d1fa5972b6e3706100bb8ddffb0aeafaf0200822520118a87e00000300000003000e017b1e76c223d1fa5972b6e3706100bb8ddffb0aeafaf0200822520118a87ef0a4b9550b000000000000000000000000000300000003020d584a4cbbfd9a4878d816512894e65918e54fae13df39a6f520fc90caea2fb00e017b1e76c223d1fa5972b6e3706100bb8ddffb0aeafaf0200822520118a87ef0a4b9550b00000000000000000000000000030000000e060017640700000000000000000000000000000300000003045a9ae1e0730536617c67ca727de00d4d197eb6afa03ac0b4ecaa097eb87813d6c005d9010000000000000000000000000000030000000000c0769f0b00000000000000";
    //     bool res = verify(root, merkleProof, keys, values);
    //     assertTrue(res);
    // }

    function testPairsVerifyProof() public returns(bool) {

        bytes32 root = hex"493825321d9ad0c473bbf85e1a08c742b4a0b75414f890745368b8953b873017";
        bytes[] memory merkleProof = new bytes[](5);
        merkleProof[0] = hex"810616010018487261766f00007c8306f7240030447365207374616c6c696f6e30447365206275696c64696e67";
        merkleProof[1] = hex"466c6661800000000000000000000000000000000000000000000000000000000000000000";
        merkleProof[2] = hex"826f400000";
        merkleProof[3] = hex"8107400000";
        merkleProof[4] = hex"410500";

        //sort keys!
        bytes[] memory keys = new bytes[](8);
        keys[0] = hex"616c6661626574";
        keys[1] = hex"627261766f";
        keys[2] = hex"64";
        keys[3] = hex"646f";
        keys[4] = hex"646f10";
        keys[5] = hex"646f67";
        keys[6] = hex"646f6765";
        keys[7] = hex"68616c70";

        bytes[] memory values = new bytes[](8);
        values[0] = hex"";
        values[1] = hex"627261766f";
        values[2] = hex"";
        values[3] = hex"76657262";
        values[4] = hex"";
        values[5] = hex"7075707079";
        values[6] = hex"0000000000000000000000000000000000000000000000000000000000000000";
        values[7] = hex"";
        bool res = verify(root, merkleProof, keys, values);
        assertTrue(res);
    }

    function test_decode_leaf() public returns(bool) {
        bytes memory proof = hex"410500";
        Input.Data memory data = Input.from(proof);
        uint8 header = data.decodeU8();
        Node.Leaf memory l = Node.decodeLeaf(data, header);
        assertEq0(l.key, hex"05");
        assertEq0(l.value, hex"");
    }

    function test_encode_leaf() public returns(bool) {
        bytes memory proof = hex"410500";
        Input.Data memory data = Input.from(proof);
        uint8 header = data.decodeU8();
        Node.Leaf memory l = Node.decodeLeaf(data, header);
        bytes memory b = Node.encodeLeaf(l);
        assertEq0(proof, b);
    }

    function test_decode_branch() public returns(bool) {

            bytes memory proof
         = hex"c10740001470757070798083809f19c0b956a97fc0175e6717d289bb0f890a67a953eb0874f89244314b34";
        Input.Data memory data = Input.from(proof);
        uint8 header = data.decodeU8();
        Node.Branch memory b = Node.decodeBranch(data, header);
        assertEq0(b.key, hex"07");
        assertEq0(b.value, hex"7075707079");
        //TODO:: test children
    }

    function test_encode_branch() public returns(bool) {

            bytes memory proof
         = hex"c10740001470757070798083809f19c0b956a97fc0175e6717d289bb0f890a67a953eb0874f89244314b34";
        Input.Data memory data = Input.from(proof);
        uint8 header = data.decodeU8();
        Node.Branch memory b = Node.decodeBranch(data, header);
        bytes memory x = Node.encodeBranch(b);
        assertEq0(proof, x);
    }
}
