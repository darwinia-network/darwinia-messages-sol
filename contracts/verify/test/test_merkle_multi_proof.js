const {expect, use} = require('chai');
const { solidity }  = require("ethereum-waffle");
const { keccakFromHexString, keccak } = require("ethereumjs-util");
const MerkleTree = require("merkletreejs").MerkleTree;
const largeValidatorAddresses = require("./data/large-validator-data")

use(solidity);

describe('MerkleMultiProofTest', function () {
    let merkleProof;

    before(async () => {
      const MerkleProof = await ethers.getContractFactory("MerkleMultiProofTest");
      merkleProof = await MerkleProof.deploy();
    });

    it('Simple merkle multi proof', async () => {
      let beefyValidatorPubKey = [
        "0x049346ec0021405ec103c2baac8feff9d6fb75851318fb03781edf29f05f2ffeb794c7f5140cce7745a91d45027df5b421342bc2446f39beaf65f705ef864841ed",
        "0x04fe6b333420b90689158643ccad94e62d707de1a80726d53aa04657fec14afd3e441e67f48e61b4e67b4c4ab17713c0737abe7ddad63bb97b1138302e1a776723",
        "0x048c49b70d152e7f9bfbfc4a7c53fb13d8855dbc221e68f7ef734f0af394d86bf1a3b28bf6c6fd814ed8772e41e7a19c2bfc261bff67b46e065d2767a547079139"
      ] 
      const tree = createMerkleTree(beefyValidatorPubKey);
      const root = tree.getRoot()
      let subKeys = beefyValidatorPubKey.slice(1, 3)
      const proofLeaves = subKeys.map(leaf => keccakFromHexString(leaf)).sort(Buffer.compare)
      const proof = tree.getMultiProof(proofLeaves)
      const proofFlags = tree.getProofFlags(proofLeaves, proof)
      const result = await merkleProof.verifyMultiProof(
        root, proofLeaves, proof, proofFlags
      )
      // expect(result).to.equal(true)
    })

    it('Large sparse merkle multi proof', async () => {
      let beefyValidatorPubKey = largeValidatorAddresses.sort();

      const leavesHashed = beefyValidatorPubKey.map(leaf => keccakFromHexString(leaf)).sort(Buffer.compare);
      const tree = new MerkleTree(leavesHashed, keccak, { sort: true });

      const root = tree.getRoot()
      const treeFlat = tree.getLayersFlat()
      const depth = tree.getDepth()
      const indices = [ 2,   4,   5,   6,   7,   8,  34,  36,  37,  38]
      const leaves = indices.map(i => leavesHashed[i])
      const proof = tree.getMultiProof(treeFlat, indices)
      const verified = tree.verifyMultiProof(root, indices, leaves, depth, proof)
      expect(verified).to.equal(true)

      const proofS = tree.getMultiProof(leaves)
      // console.log(tree.getHexMultiProof(treeFlat, indices))
      // console.log(tree.getHexMultiProof(leaves))
      const proofFlags = tree.getProofFlags(leaves, proofS)
      const result = await merkleProof.verifyMultiProof(
        root, leaves, proofS, proofFlags
      )
      // expect(result).to.equal(true)
    })

    it('Large sparse merkle multi proof with indices', async () => {
      let beefyValidatorPubKey = largeValidatorAddresses.sort();

      const leavesHashed = beefyValidatorPubKey.map(leaf => keccakFromHexString(leaf)).sort(Buffer.compare);
      const tree = new MerkleTree(leavesHashed, keccak, { sort: true });

      const root = tree.getRoot()
      const treeFlat = tree.getLayersFlat()
      const depth = tree.getDepth()
      const indices = [ 2,   4,   5,   6,   7,   8,  34,  36,  37,  38]
      const leaves = indices.map(i => leavesHashed[i])
      const proof = tree.getMultiProof(treeFlat, indices)

      const verified = tree.verifyMultiProof(root, indices, leaves, depth, proof)
      expect(verified).to.equal(true)

      const proofFlags = tree.getProofFlags(indices, proof)
      // const result = await merkleProof.verifyMultiProof(
      //   root, leaves, proof, proofFlags
      // )
      // expect(result).to.equal(true)
    })
});

function createMerkleTree(leavesHex) {
  const leavesHashed = leavesHex.map(leaf => keccakFromHexString(leaf)).sort(Buffer.compare);
  const merkleTree = new MerkleTree(leavesHashed, keccak, { sort: true });

  return merkleTree;
}
