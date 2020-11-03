const MerkleProofTest = artifacts.require('MerkleProofTest');

describe('MerkleProofTest', function (accounts) {

    before(async () => {

    });

    it('MerkleProof test', async () => {
        let contract = await MerkleProofTest.new()
        let ret = await contract.testSimplePairVerifyProof()
        assert(ret, true);
    }).timeout(200000);
});