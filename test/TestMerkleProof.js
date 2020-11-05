
const { expect } = require("chai");

describe('MerkleProofTest', function (accounts) {

    before(async () => {
        MerkleProofTest = await ethers.getContractFactory("MerkleProofTest");

        contract = await MerkleProofTest.deploy();
        await contract.deployed();
    });
    // it('MerkleProof test', async () => {
    //     let contract = await MerkleProofTest.new()
    //     let ret = await contract.testSimplePairVerifyProof()
    //     assert(ret, true);
    // }).timeout(200000);

    it('MerkleProof testPairsVerifyProofBlake2b', async () => {
        // await contract.testPairsVerifyProofBlake2b();
        await contract.test_decode_leaf();
        await contract.test_encode_leaf();
        await contract.test_decode_branch();
        await contract.test_decode_branch();
    }).timeout(200000);
});
