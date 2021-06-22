const {expect, use} = require('chai');
const { solidity }  = require("ethereum-waffle");
const { keccakFromHexString, keccak } = require("ethereumjs-util");
const MerkleTree = require("merkletreejs").MerkleTree;

use(solidity);

describe('MerkleProofTest', function () {
    let merkleProof;

    before(async () => {
      const MerkleProof = await ethers.getContractFactory("MerkleProofTest");
      merkleProof = await MerkleProof.deploy();
    });

    it('Compare gas used to trie', async () => {
      let beefyValidatorPubKey = [
        "0x039346ec0021405ec103c2baac8feff9d6fb75851318fb03781edf29f05f2ffeb7",
        "0x03fe6b333420b90689158643ccad94e62d707de1a80726d53aa04657fec14afd3e",
        "0x03fe6b333420b90689158643ccad94e62d707de1a80726d53aa04657fec14afd3e"
      ] 
      const validatorsMerkleTree = createMerkleTree(beefyValidatorPubKey);
      const validatorsLeaf0 = validatorsMerkleTree.getHexLeaves()[0];
      const validator0PubKeyMerkleProof = validatorsMerkleTree.getHexProof(validatorsLeaf0);
      const result = await merkleProof.verifyMerkleLeafAtPosition(
        validatorsMerkleTree.getHexRoot(),
        validatorsLeaf0,
        0,
        validatorsMerkleTree.getLeaves().length,
        validator0PubKeyMerkleProof 
      )
      // expect(result).to.equal(true)
    })

    // it("verify merkle proof with position", async function () {
    //   const hashedData = [...generateSampleData(100)].map(x => keccakFromString(x))

    //   const cases = [
    //     // 1 leaf
    //     { data: hashedData.slice(0, 1), proofForLeaf: 0, verifyLeaf: 0, succeed: true },
    //     { data: hashedData.slice(0, 1), proofForLeaf: 0, verifyLeaf: 1, succeed: false },

    //     // 3 leaves
    //     { data: hashedData.slice(0, 3), proofForLeaf: 0, verifyLeaf: 0, succeed: true },
    //     { data: hashedData.slice(0, 3), proofForLeaf: 0, verifyLeaf: 1, succeed: false },
    //     { data: hashedData.slice(0, 3), proofForLeaf: 0, verifyLeaf: 2, succeed: false },
    //     { data: hashedData.slice(0, 3), proofForLeaf: 1, verifyLeaf: 0, succeed: false },
    //     { data: hashedData.slice(0, 3), proofForLeaf: 1, verifyLeaf: 1, succeed: true },
    //     { data: hashedData.slice(0, 3), proofForLeaf: 1, verifyLeaf: 2, succeed: false },
    //     { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 0, succeed: false },
    //     { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 1, succeed: false },
    //     { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 2, succeed: true },
    //     { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 3, succeed: false },

    //     // 5 leaves
    //     { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 2, succeed: true },
    //     { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 1, succeed: false },
    //     { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 3, succeed: false },

    //     // 8 leaves
    //     { data: hashedData.slice(0, 8), proofForLeaf: 5, verifyLeaf: 5, succeed: true },
    //     { data: hashedData.slice(0, 8), proofForLeaf: 5, verifyLeaf: 4, succeed: false },
    //     { data: hashedData.slice(0, 8), proofForLeaf: 5, verifyLeaf: 6, succeed: false },

    //     // 9 leaves
    //     { data: hashedData.slice(0, 9), proofForLeaf: 5, verifyLeaf: 5, succeed: true },
    //     { data: hashedData.slice(0, 9), proofForLeaf: 5, verifyLeaf: 4, succeed: false },
    //     { data: hashedData.slice(0, 9), proofForLeaf: 5, verifyLeaf: 6, succeed: false },

    //     // 100 leaves
    //     { data: hashedData.slice(0, 100), proofForLeaf: 27, verifyLeaf: 27, succeed: true },
    //     { data: hashedData.slice(0, 100), proofForLeaf: 27, verifyLeaf: 26, succeed: false },
    //     { data: hashedData.slice(0, 100), proofForLeaf: 27, verifyLeaf: 28, succeed: false },
    //   ]

    //   for (const c of cases) {
    //     it(`Should ${c.succeed ? "succeed" : "fail"} for ${c.data.length} leaves with a proof for leaf at position ${
    //       c.proofForLeaf
    //     } and verifying leaf at position ${c.verifyLeaf}`, async function () {
    //       const tree = new MerkleTree(c.data, keccak, { sort: false })

    //       tree.print()

    //       const root = tree.getRoot()
    //       const hexRoot = tree.getHexRoot()

    //       const leaf = hashedData[c.proofForLeaf]
    //       const hexLeaf = MerkleTree.bufferToHex(leaf)

    //       const proof = tree.getProof(leaf, c.proofForLeaf).map(p => p.data) as Buffer[]
    //       const hexProof = tree.getHexProof(leaf)

    //       // console.log({
    //       //   proof: proof.map(p => p.toString('hex')),
    //       //   hexProof: hexProof,
    //       // })

    //       // expect(tree.verifyMultiProof(root, [c.proofForLeaf], [leaf], tree.getDepth(), proof)).to.be.true

    //       const result = await verification.verifyMerkleLeafAtPosition(
    //         hexRoot,
    //         hexLeaf,
    //         c.verifyLeaf,
    //         c.data.length,
    //         hexProof
    //       )
    //       expect(result).to.equal(c.succeed)
    //     })
    //   }
    // })

    // it("Test if correct hash, but wrong position", async function () {
    //   const tree = new MerkleTree(hashedData, keccak, { sort: false })

    //   const root = tree.getRoot()
    //   const hexRoot = tree.getHexRoot()

    //   const leaf = hashedData[5]
    //   const hexLeaf = MerkleTree.bufferToHex(leaf)

    //   const proof = tree.getProof(leaf, 5)
    //   const hexProof = tree.getHexProof(leaf)

    //   tree.print()

    //   expect(tree.verify(proof, leaf, root)).to.be.true

    //   const result = await verification.verifyMerkleLeafAtPosition(hexRoot, hexLeaf, 5, hashedData.length, hexProof)
    //   expect(result).to.be.true
    // })
});

function createMerkleTree(leavesHex) {
  const leavesHashed = leavesHex.map(leaf => keccakFromHexString(leaf));
  const merkleTree = new MerkleTree(leavesHashed, keccak, { sort: false });

  return merkleTree;
}
