const {expect, use} = require('chai');
const { solidity }  = require("ethereum-waffle");
const { keccakFromHexString, keccak, bufferToHex } = require("ethereumjs-util");
const { MerkleTree } = require("merkletreejs");
const largeValidatorAddresses = require("./data/large-validator-data")
const { SparseMerkleTree } = require("../src/utils/sparseMerkleTree.js")

use(solidity);

describe('MerkleMultiProofTest', function () {
    let merkleProof
    let sparseMerkleProof

    before(async () => {
      const MerkleProof = await ethers.getContractFactory("MerkleMultiProofTest")
      merkleProof = await MerkleProof.deploy()
      const SpaseMerkleMultiProof = await ethers.getContractFactory("SparseMerkleMultiProofTest")
      sparseMerkleProof = await SpaseMerkleMultiProof.deploy()
    });

    it('Simple merkle multi proof', async () => {
      let beefyValidatorPubKey = [
        "0x049346ec0021405ec103c2baac8feff9d6fb75851318fb03781edf29f05f2ffeb794c7f5140cce7745a91d45027df5b421342bc2446f39beaf65f705ef864841ed",
        "0x04fe6b333420b90689158643ccad94e62d707de1a80726d53aa04657fec14afd3e441e67f48e61b4e67b4c4ab17713c0737abe7ddad63bb97b1138302e1a776723",
        "0x048c49b70d152e7f9bfbfc4a7c53fb13d8855dbc221e68f7ef734f0af394d86bf1a3b28bf6c6fd814ed8772e41e7a19c2bfc261bff67b46e065d2767a547079139",
        "0x046c4a9704d28c9e009550a9a836aff5e99bbebb73bad6a478af44d45c42101d86216242753b216330e6037b23748d26ed99207d2e7b48cba2a5e3461ff9ded54e"
      ].sort()
      const leavesHashed = beefyValidatorPubKey.map(leaf => keccakFromHexString(leaf)).sort(Buffer.compare);
      const tree = new MerkleTree(leavesHashed, keccak, { sort:true });
      const root = tree.getRoot()
      let subKeys = beefyValidatorPubKey.slice(1, 3)
      const proofLeaves = subKeys.map(leaf => keccakFromHexString(leaf)).sort(Buffer.compare)
      const proof = tree.getMultiProof(proofLeaves)
      const proofFlags = tree.getProofFlags(proofLeaves, proof)
      const result = await merkleProof.verifyMultiProof(
        root, proofLeaves, proof, proofFlags
      )
      expect(result).to.equal(true)
    })

    it('Simple sparse merkle multi proof with indices', async () => {
      let leafs = ['a', 'b', 'c', 'd'].map(x => keccak(Buffer.from(x)))
      const tree = new SparseMerkleTree(leafs)
      // tree.print()
      const indices = [2, 1]
      // console.log(indices)
      const proof = tree.proof(indices)
      // console.log(tree.proofHex(indices))
      let values ={}
      for (let index of indices) {
        values[index] = leafs[index]
      }
      const verified = tree.verify(values, proof)
      expect(verified).to.equal(true)
      let leaves = indices.map(i => bufferToHex(leafs[i]))
      // console.log(leaves)
      const result = await sparseMerkleProof.verifyMultiProofWithDict(
        tree.rootHex(), tree.height(), indices, leaves, tree.proofHex(indices)
      )
      expect(result).to.equal(true)
    })

    it('Simple merkle multi proof with indices', async () => {
      let leafs = ['a', 'b', 'c', 'd'].map(x => keccak(Buffer.from(x)))
      // leafs = leafs.sort(Buffer.compare)
      const tree = new MerkleTree(leafs, keccak)
      // tree.print()
      const root = tree.getRoot()
      const treeFlat = tree.getLayersFlat()
      // console.log(treeFlat.map(x => x.toString('hex')))
      const depth = tree.getDepth()
      // console.log(depth)
      const indices = [2, 1]
      // console.log(indices)
      // console.log(leafs.map(x => x.toString('hex')))
      const leaves = indices.map(i => leafs[i])
      // console.log(leaves.map(x => x.toString('hex')))
      // let proof = tree.getMultiProof(leaves)
      const proof = tree.getMultiProof(treeFlat, indices)
      const verified = tree.verifyMultiProof(root, indices, leaves, depth, proof)
      expect(verified).to.equal(true)
      // console.log(proof.map(x => x.toString('hex')))
      // const proofFlags = tree.getProofFlags(leaves, proof)
      // console.log(proofFlags)

      const result = await sparseMerkleProof.verifyMultiProofWithDict(
        root, depth, indices, leaves, proof
      )
      expect(result).to.equal(true)
    })

    it('Simple merkle multi proof with indices 2', async () => {
      let beefyValidatorPubKey = [
        "0x049346ec0021405ec103c2baac8feff9d6fb75851318fb03781edf29f05f2ffeb794c7f5140cce7745a91d45027df5b421342bc2446f39beaf65f705ef864841ed",
        "0x04fe6b333420b90689158643ccad94e62d707de1a80726d53aa04657fec14afd3e441e67f48e61b4e67b4c4ab17713c0737abe7ddad63bb97b1138302e1a776723",
        "0x048c49b70d152e7f9bfbfc4a7c53fb13d8855dbc221e68f7ef734f0af394d86bf1a3b28bf6c6fd814ed8772e41e7a19c2bfc261bff67b46e065d2767a547079139",
        "0x049cae155ab0892c730cf99a62005c2d37dd72b56fb1d5c4d399b1fa5d70dfa80dceb905729958329711aa1a2d75dec02db18c1568c6d1e5b4a270a9ac75d79d3b",
      ]
      const leafs = beefyValidatorPubKey.map(leaf => keccakFromHexString(leaf)).sort(Buffer.compare);
      const tree = new SparseMerkleTree(leafs)
      // tree.print()
      const indices = [2, 1]
      // console.log(indices)
      // console.log(leafs.map(x => x.toString('hex')))
      const leaves = indices.map(i => leafs[i])
      // console.log(leaves.map(x => x.toString('hex')))
      const proof = tree.proofHex(indices)
      const result = await sparseMerkleProof.verifyMultiProofWithDict(
        tree.rootHex(), tree.height(), indices, leaves, proof
      )
      expect(result).to.equal(true)
    })

    it('Large sparse merkle multi proof', async () => {
      let beefyValidatorPubKey = largeValidatorAddresses.sort();

      const leavesHashed = beefyValidatorPubKey.map(leaf => keccakFromHexString(leaf)).sort(Buffer.compare);
      const tree = new SparseMerkleTree(leavesHashed)
      let indices = [ 2,   4,   5,   6,   7,   8,  34,  36,  37,  38,  39,  40, 66,  68,  69,  70,  71,  72,  98, 100, 101, 102, 103, 104, 130, 132, 133, 134, 135, 136, 162, 164, 165, 166, 167, 168, 194, 196, 197, 198, 199, 200, 226, 228, 229, 230, 231, 232, 258, 260, 261, 262, 263, 264, 290, 292, 293, 294, 295, 296, 322, 324, 325, 326, 327, 328, 354, 356, 357, 358, 359, 360, 386, 388, 389, 390, 391, 392, 418, 420, 421, 422, 423, 424, 450, 452, 453, 454, 455, 456, 482, 484, 485, 486, 487, 488 ]
      indices = indices.reverse()
      const proof = tree.proof(indices)
      let values ={}
      for (let index of indices) {
        values[index] = leavesHashed[index]
      }
      const verified = tree.verify(values, proof)
      expect(verified).to.equal(true)

      const leaves = indices.map(i => leavesHashed[i])
      const result = await sparseMerkleProof.verifyMultiProofWithDict(
        tree.rootHex(), tree.height(), indices, leaves, tree.proofHex(indices)
      )
      expect(result).to.equal(true)
    })


    it('Large sparse merkle multi proof with indices', async () => {
      let beefyValidatorPubKey = largeValidatorAddresses.sort();

      const leavesHashed = beefyValidatorPubKey.map(leaf => keccakFromHexString(leaf)).sort(Buffer.compare);
      const tree = new SparseMerkleTree(leavesHashed)
      // tree.print()
      const indices = [8 , 7,  6,  5,  4,  1]
      const proof = tree.proof(indices)
      let values ={}
      for (let index of indices) {
        values[index] = leavesHashed[index]
      }
      const verified = tree.verify(values, proof)
      expect(verified).to.equal(true)

      const leaves = indices.map(i => leavesHashed[i])
      // console.log(leaves.map(x => x.toString('hex')))
      const result = await sparseMerkleProof.verifyMultiProofWithDict(
        tree.rootHex(), tree.height(), indices, leaves, tree.proofHex(indices)
      )
      expect(result).to.equal(true)
    })
});
