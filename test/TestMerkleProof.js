const MerkleProofTest = artifacts.require('MerkleProofTest');

describe('MerkleProofTest', function (accounts) {

    before(async () => {

    });

    // it('MerkleProof test', async () => {
    //     let contract = await MerkleProofTest.new()
    //     let ret = await contract.testSimplePairVerifyProof()
    //     assert(ret, true);
    // }).timeout(200000);

    it('MerkleProof testPairsVerifyProofBlake2b', async () => {
        let contract = await MerkleProofTest.new()
        assert(await contract.testPairsVerifyProofBlake2b(), true);
        assert(await contract.test_decode_leaf(), true);
        assert(await contract.test_encode_leaf(), true);
        assert(await contract.test_decode_branch(), true);
        assert(await contract.test_decode_branch(), true);
    }).timeout(200000);
});
