pragma solidity >=0.6.0 <0.7.0;

import "@darwinia/contracts-utils/contracts/ds-test/test.sol";
import "./CompactMerkleProof.sol";
pragma experimental ABIEncoderV2;

contract CompactMerkleProofTest is CompactMerkleProof, DSTest {
    function setUp() public {}

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

    function testSimplePairVerifyProof() public returns (bool) {
        bytes32 root = hex"36d59226dcf98198b07207ee154ebea246a687d8c11191f35b475e7a63f9e5b4";
        bytes[] memory proof = new bytes[](1);
        proof[0] = hex"44646f00";
        bytes[] memory keys = new bytes[](1);
        keys[0] = hex"646f";
        bytes[] memory values = new bytes[](1);
        values[0] = hex"76657262";
        bool res = verify(root, proof, keys, values);
        assertTrue(res);
		return res;
    }

    function testPairVerifyProof() public returns (bool) {
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
		return res;
    }

    function testPairsVerifyProofBlake2b() public returns (bool) {
		bytes32 root = hex"8b5b6ad240751b4af62bf0e939731564bfb41b9bfbe01e32e00154eae31cfe43";
        bytes[] memory merkleProof = new bytes[](1);
        merkleProof[0] = hex"810006000c420200144203080405";

        bytes[] memory keys = new bytes[](1);
        keys[0] = hex"0102";
        bytes[] memory values = new bytes[](1);
        values[0] = hex"01";
        bool res = verify(root, merkleProof, keys, values);
        assertTrue(res);
		return res;
    }

    function testPairsVerifyProof() public returns (bool) {
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
		return res;
    }

    function test_decode_leaf() public {
        bytes memory proof = hex"410500";
        Input.Data memory data = Input.from(proof);
        uint8 header = data.decodeU8();
        Node.Leaf memory l = Node.decodeLeaf(data, header);
        assertEq0(l.key, hex"05");
        assertEq0(l.value, hex"");
    }

    function test_encode_leaf() public {
        bytes memory proof = hex"410500";
        Input.Data memory data = Input.from(proof);
        uint8 header = data.decodeU8();
        Node.Leaf memory l = Node.decodeLeaf(data, header);
        bytes memory b = Node.encodeLeaf(l);
        assertEq0(proof, b);
    }

    function test_decode_branch() public {
		bytes memory proof = hex"c10740001470757070798083809f19c0b956a97fc0175e6717d289bb0f890a67a953eb0874f89244314b34";
        Input.Data memory data = Input.from(proof);
        uint8 header = data.decodeU8();
        Node.Branch memory b = Node.decodeBranch(data, header);
        assertEq0(b.key, hex"07");
        assertEq0(b.value, hex"7075707079");
        //TODO:: test children
    }

    function test_encode_branch() public {
		bytes memory proof  = hex"c10740001470757070798083809f19c0b956a97fc0175e6717d289bb0f890a67a953eb0874f89244314b34";
        Input.Data memory data = Input.from(proof);
        uint8 header = data.decodeU8();
        Node.Branch memory b = Node.decodeBranch(data, header);
        bytes memory x = Node.encodeBranch(b);
        assertEq0(proof, x);
    }
}
