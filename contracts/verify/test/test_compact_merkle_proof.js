const {expect, use} = require('chai');
const { solidity }  = require("ethereum-waffle");

use(solidity);

describe('CompactMerkleProofTest', function () {
    let SimpleMerkleProofTest;

    before(async () => {
      CompactMerkleProofTest = await ethers.getContractFactory("CompactMerkleProofTest");
      compactMerkleProofTest = await CompactMerkleProofTest.deploy();
      await compactMerkleProofTest.deployed();
    });

    it('Compare gas used to trie', async () => {
      let root = "0x0cd6a3836ec1fff4784c938237a77474e6742aef338c736f75ea57721f39b4ae";        
      let proof = ["0x8100110100800c851a81b2d4d5bb0bb959dbfeb21cf3f475ac5be781caed6fe7fc73723b69dc800c851a81b2d4d5bb0bb959dbfeb21cf3f475ac5be781caed6fe7fc73723b69dc", "0x4000"]
      let keys = ["0x00"]
      let values = ["0x049346ec0021405ec103c2baac8feff9d6fb75851318fb03781edf29f05f2ffeb794c7f5140cce7745a91d45027df5b421342bc2446f39beaf65f705ef864841ed"]
      await compactMerkleProofTest.testCompactVerify(root, proof, keys, values)
    })

    // it('TestCompactMerkleProof', async () => {
        // await compactMerkleProofTest.testAuthorySetVerifyProof()
        // await compactMerkleProofTest.testSimplePairVerifyProof()
        // await compactMerkleProofTest.testPairVerifyProof()
        // await compactMerkleProofTest.testPairsVerifyProof()

        // await compactMerkleProofTest.test_decode_leaf()
        // await compactMerkleProofTest.test_encode_leaf()
        // await compactMerkleProofTest.test_decode_branch()
        // await compactMerkleProofTest.test_encode_branch()
    // })
});
