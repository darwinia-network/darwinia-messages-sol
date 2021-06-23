const {expect, use} = require('chai');
const { solidity }  = require("ethereum-waffle");
const { keccak, keccakFromString } = require("ethereumjs-util")
const { buf2hex, getMerkleRoot, hex2buf } = require("./shared/utils.js")
const { MerkleTree } = require("merkletreejs")
const generateSampleData = require("./shared/sampleData")

use(solidity);

describe('MerkleProofTest', function () {
  let merkleProof
  let hexData

  context("List Data Structure", function () {
    beforeEach(async function () {
      const MerkleProof = await ethers.getContractFactory("MerkleProofTest");
      verification = await MerkleProof.deploy();
      const hashedData = [...generateSampleData(100)].map(x => keccakFromString(x))
      hexData = hashedData.map(buf2hex)
    })

    it("Should verify an array of hashed data, given the commitment is correct", async function () {
      const commitment = hexData.reduce((prev, curr) =>
        ethers.utils.solidityKeccak256(["bytes32", "bytes32"], [prev, curr])
      )
      const result = await verification.verifyMessageArray(hexData, commitment)
      expect(result).to.be.true
    })

    it("Should not verify an array of hashed data, when the commitment is not correct", async function () {
      const commitment = hexData.reduce((prev, curr) =>
        ethers.utils.solidityKeccak256(["bytes32", "bytes32"], [prev, curr])
      )
      const badData = ["s", "n", "O", "w", "f", "U", "n", "k"].map(x => keccakFromString(x)).map(buf2hex)
      const result = await verification.verifyMessageArray(badData, commitment)
      expect(result).to.be.false
    })
    it("Should not revert when called", async function () {
      const commitment = hexData.reduce((prev, curr) =>
        ethers.utils.solidityKeccak256(["bytes32", "bytes32"], [prev, curr])
      )
      await expect(verification.verifyMessageArray(hexData, commitment)).to.not.be.reverted
    })

    it("Should verify message array unpacked", async function () {
      const commitment = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["bytes32[]"], [ hexData ]))
      const result = await verification.verifyMessagesArrayUnpacked(hexData, commitment)
      expect(result).to.be.true
    })
  })

  context("Merkle Tree Data Structure", function () {
    beforeEach(async function () {
      const MerkleProof = await ethers.getContractFactory("MerkleProofTest");
      verification = await MerkleProof.deploy();
      hashedData = [...generateSampleData(100)].map(x => keccakFromString(x))
      hexData = hashedData.map(buf2hex)
    })

    describe("When verifying a single leaf in the tree", function () {
      it("Should verify an array of hashed data, given the commitment is correct", async function () {
        const tree = new MerkleTree(hashedData, keccak, { sort: true })
        const root = tree.getRoot()
        const hexRoot = tree.getHexRoot()
        for (let i = 0; i < hashedData.length; i++) {
          const leaf = hashedData[i]
          const hexLeaf = MerkleTree.bufferToHex(leaf)
          const proof = tree.getProof(leaf)
          const hexProof = tree.getHexProof(leaf)
          const result = await verification.verifyMerkleLeaf(hexRoot, hexLeaf, hexProof)
          expect(tree.verify(proof, leaf, root)).to.be.true
          expect(result).to.be.true
        }
      })

      describe("verify merkle proof with position", async function () {
        const hashedData = [...generateSampleData(100)].map(x => keccakFromString(x))
        const cases = [
          // 1 leaf
          { data: hashedData.slice(0, 1), proofForLeaf: 0, verifyLeaf: 0, succeed: true },
          { data: hashedData.slice(0, 1), proofForLeaf: 0, verifyLeaf: 1, succeed: false },

          // 3 leaves
          { data: hashedData.slice(0, 3), proofForLeaf: 0, verifyLeaf: 0, succeed: true },
          { data: hashedData.slice(0, 3), proofForLeaf: 0, verifyLeaf: 1, succeed: false },
          { data: hashedData.slice(0, 3), proofForLeaf: 0, verifyLeaf: 2, succeed: false },
          { data: hashedData.slice(0, 3), proofForLeaf: 1, verifyLeaf: 0, succeed: false },
          { data: hashedData.slice(0, 3), proofForLeaf: 1, verifyLeaf: 1, succeed: true },
          { data: hashedData.slice(0, 3), proofForLeaf: 1, verifyLeaf: 2, succeed: false },
          { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 0, succeed: false },
          { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 1, succeed: false },
          { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 2, succeed: true },
          { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 3, succeed: false },

          // 5 leaves
          { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 2, succeed: true },
          { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 1, succeed: false },
          { data: hashedData.slice(0, 3), proofForLeaf: 2, verifyLeaf: 3, succeed: false },

          // 8 leaves
          { data: hashedData.slice(0, 8), proofForLeaf: 5, verifyLeaf: 5, succeed: true },
          { data: hashedData.slice(0, 8), proofForLeaf: 5, verifyLeaf: 4, succeed: false },
          { data: hashedData.slice(0, 8), proofForLeaf: 5, verifyLeaf: 6, succeed: false },

          // 9 leaves
          { data: hashedData.slice(0, 9), proofForLeaf: 5, verifyLeaf: 5, succeed: true },
          { data: hashedData.slice(0, 9), proofForLeaf: 5, verifyLeaf: 4, succeed: false },
          { data: hashedData.slice(0, 9), proofForLeaf: 5, verifyLeaf: 6, succeed: false },

          // 100 leaves
          { data: hashedData.slice(0, 100), proofForLeaf: 27, verifyLeaf: 27, succeed: true },
          { data: hashedData.slice(0, 100), proofForLeaf: 27, verifyLeaf: 26, succeed: false },
          { data: hashedData.slice(0, 100), proofForLeaf: 27, verifyLeaf: 28, succeed: false },
        ]

        for (const c of cases) {
          it(`Should ${c.succeed ? "succeed" : "fail"} for ${c.data.length} leaves with a proof for leaf at position ${
            c.proofForLeaf
          } and verifying leaf at position ${c.verifyLeaf}`, async function () {
            const tree = new MerkleTree(c.data, keccak, { sort: false })
            // tree.print()
            const root = tree.getRoot()
            const hexRoot = tree.getHexRoot()

            const leaf = hashedData[c.proofForLeaf]
            const hexLeaf = MerkleTree.bufferToHex(leaf)

            const proof = tree.getProof(leaf, c.proofForLeaf).map(p => p.data)
            const hexProof = tree.getHexProof(leaf)

            // console.log({
            //   proof: proof.map(p => p.toString('hex')),
            //   hexProof: hexProof,
            // })

            // expect(tree.verifyMultiProof(root, [c.proofForLeaf], [leaf], tree.getDepth(), proof)).to.be.true

            const result = await verification.verifyMerkleLeafAtPosition(
              hexRoot,
              hexLeaf,
              c.verifyLeaf,
              c.data.length,
              hexProof
            )
            expect(result).to.equal(c.succeed)
          })
        }
      })

      it("Test if correct hash, but wrong position", async function () {
        const tree = new MerkleTree(hashedData, keccak, { sort: false })
        const root = tree.getRoot()
        const hexRoot = tree.getHexRoot()
        const leaf = hashedData[5]
        const hexLeaf = MerkleTree.bufferToHex(leaf)

        const proof = tree.getProof(leaf, 5)
        const hexProof = tree.getHexProof(leaf)
        // tree.print()
        expect(tree.verify(proof, leaf, root)).to.be.true
        const result = await verification.verifyMerkleLeafAtPosition(hexRoot, hexLeaf, 5, hashedData.length, hexProof)
        expect(result).to.be.true
      })

      it("Should not verify an array of hashed data, when the commitment is not correct", async function () {
        const tree = new MerkleTree(hashedData, keccak, { sort: true })

        const root = tree.getRoot()
        const hexRoot = tree.getHexRoot()

        const correctLeaf = hashedData[0]
        const incorrectLeaf = keccakFromString("0")
        const incorrectLeafHex = MerkleTree.bufferToHex(incorrectLeaf)

        const proof = tree.getProof(correctLeaf)
        const hexProof = tree.getHexProof(correctLeaf)

        const result = await verification.verifyMerkleLeaf(hexRoot, incorrectLeafHex, hexProof)

        expect(tree.verify(proof, incorrectLeaf, root)).to.be.false
        expect(result).to.be.false
      })
      it("Should not revert when called", async function () {
        const tree = new MerkleTree(hexData, keccak, { sort: true })
        const hexRoot = tree.getHexRoot()
        const hexLeaf = hexData[0]
        const hexProof = tree.getHexProof(hex2buf(hexLeaf))

        await expect(verification.verifyMerkleLeaf(hexRoot, hexLeaf, hexProof)).to.not.be.reverted
      })
    })

    describe("When verifying all leaves in the tree", function () {
      // FIXME
      it.skip("Should verify a commitment correctly when the number of leaves is even", async function () {
        const { hexRoot, sortedLeaves, verification } = await testFixture({
          leafCount: 100,
        })
        const result = await verification.verifyMerkleAll(sortedLeaves, hexRoot)
        expect(result).to.be.true
      })

      // FIXME
      it.skip("Should verify a commitment correctly when the number of leaves is odd", async function () {
        const { hexRoot, sortedLeaves, verification } = await testFixture({
          leafCount: 5,
        })
        const result = await verification.verifyMerkleAll(sortedLeaves, hexRoot)
        expect(result).to.be.true
      })

      it("Should verify a commitment correctly with 1 leaf", async function () {
        const { hexRoot, sortedLeaves, verification } = await testFixture({
          leafCount: 1,
        })
        const result = await verification.verifyMerkleAll(sortedLeaves, hexRoot)
        expect(result).to.be.true
      })

      it("Should verify a commitment correctly with 2 leaves", async function () {
        const { hexRoot, sortedLeaves, verification } = await testFixture({
          leafCount: 2,
        })
        const result = await verification.verifyMerkleAll(sortedLeaves, hexRoot)
        expect(result).to.be.true
      })

      it("Should not verify an array of hashed data, when the commitment is not correct", async function () {
        const { hexRoot, sortedLeaves, verification } = await testFixture({
          leafCount: 10,
        })
        sortedLeaves[2] = sortedLeaves[3]

        const result = await verification.verifyMerkleAll(sortedLeaves, hexRoot)
        expect(result).to.be.false
      })
    })
  })

});

async function testFixture(options) {
  const MerkleProof = await ethers.getContractFactory("MerkleProofTest");
  verification = await MerkleProof.deploy();

  const hashedData = [...generateSampleData(options.leafCount)].map(x => keccakFromString(x))
  const hexData = hashedData.map(buf2hex)

  const sortedLeaves = hashedData.sort(Buffer.compare).map(buf2hex)
  const hexRoot = getMerkleRoot(sortedLeaves.map(x => x))

  return {
    verification,
    hashedData,
    hexData,
    sortedLeaves,
    hexRoot,
  }
}
