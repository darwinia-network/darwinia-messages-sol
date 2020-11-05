const CompactMerkleProofTest = artifacts.require('CompactMerkleProofTest');
const SimpleMerkleProofTest = artifacts.require('SimpleMerkleProofTest');

describe('MerkleProofTest', function (accounts) {

    before(async () => {

    });

    it('CompactMerkleProofTest testCompactMerkleProofTest', async () => {
        let contract = await CompactMerkleProofTest.new()
        assert(await contract.testSimplePairVerifyProof(), true);
        assert(await contract.testPairVerifyProof(), true);
        assert(await contract.testPairsVerifyProof(), true);

        assert(await contract.test_decode_leaf(), true);
        assert(await contract.test_encode_leaf(), true);
        assert(await contract.test_decode_branch(), true);
        assert(await contract.test_encode_branch(), true);
    }).timeout(200000);

    it('SimpleMerkleProof testSimpleMerkleProof', async () => {
        let contract = await SimpleMerkleProofTest.new()
        assert(await contract.testNonCompactMerkleProof(), true);
    }).timeout(200000);
});
