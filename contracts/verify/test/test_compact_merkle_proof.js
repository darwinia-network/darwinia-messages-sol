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
      let root = "0xc91f159b4aafb358bc0c53515f1b973a39eb4569ece5b392b9ad994fd465f26b";        
      let proof = ["0x8100110100800c851a81b2d4d5bb0bb959dbfeb21cf3f475ac5be781caed6fe7fc73723b69dc807d65e4175ef59ffa7700ef6ad07789c01d7504edf24659c7162c46c03e5a6490", "0x4000"]
      let keys = ["0x00"]
      let values = ["0x049346ec0021405ec103c2baac8feff9d6fb75851318fb03781edf29f05f2ffeb794c7f5140cce7745a91d45027df5b421342bc2446f39beaf65f705ef864841ed"]
      await compactMerkleProofTest.testCompactVerify(root, proof, keys, values)
    })

    it('Large authority gas used', async () => {
      let root = "0x535ba85778cce9adc0f71f9897b0aa8fbeee043fb4901db50e2325d32b1e00a1";        
      let proof = ["0x80ffff00803029c45b76e8e6cf72beb2995cb34f05d6efc99fa926e74622321c45bade14e880751ed722cd8683b829083a8c8189e25424c69e6f581eac9e4e4aaa6a24b27b9b80cd468876c1e6c9dd095f1a9e2a2ed0462bff58ad54253f7616f2a3a57d3c5be880a8cd3d099cec81f57958af02d2b0c921f70dbb1fb69ab7d8a0c72d68135acd9d800fd1b8d8e8f3d197ae60101bf56dfcf60b6e7441c7e7ae452e47084406a1325580cb7904a0eeb54c24c62f3adc512ae36998f8bbc98d4d1affb2fcfd84f0472ff4804603efc85969d8b742dffae5f0311e5f450285e74c244a25d3ee5f5a27d98ee88029ab2ed8c6affa9eb58a3f929076566e4bb3cac0b43268ecc6736b0837b6787680f6206021e915af4b6d96623e28fc674e7bae10c4a518c6b677919b19f7e1f1d980c6771ec6b0b5a2500cf7959fc0925a36b19f1fa7519c686c0a403210b57c601280f3ee42122e45f69a1b43a483d133d92ef5af658f8ad1f0e2070b85741d76704580c6ff05f4eeb4e98d865905ef123dba3588a35c2d000741cdc7e30c23877d575c8012cc1b1e5b0d0a279bc79bfae20f91aec70b6583aa8b677ca8b7a5254593464b8036d1ca5bbc3bf0d03184d77bb307a5bac1e079f5f4e3bbb579cbc93e591df94d805f4d856f8b0d784fdf217b8453897635d8f26e9a35e2f9b269e29d233ce4c551", "0x8033330080a4976130a23a2e5bf9fdc4b9b5e3ba71904846962730ea41abea86500b09f360800c851a81b2d4d5bb0bb959dbfeb21cf3f475ac5be781caed6fe7fc73723b69dc80af449ad6f00c0e3551595787c6572a4421992a394793d59c44320c4463361dd9800df68412b644d69bcaa67f632f65e78ee89dcbaef93519cf3f40523ad5ff7f8280c9af3cc780afa2f58a53e34be26d82b05b1b5a02ac8f7b55c32da741bd0052e5803bf12b455b99bdd9768e71ebcd6ffd31b964a4b206dd7171aec47db44a826778801b406d9fa85171805bc81c3affd09497922b9eaf0501c7684c4f53a495b92777", "0x4000"]
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
