const {expect, use} = require('chai');
const { solidity }  = require("ethereum-waffle");
const { keccakFromHexString, keccak } = require("ethereumjs-util");
const MerkleTree = require("merkletreejs").MerkleTree;
const largeValidatorAddresses = require("./data/large-validator-data")

use(solidity);

describe('MerkleProofTest', function () {
    let merkleProof;

    before(async () => {
      const MerkleProof = await ethers.getContractFactory("MerkleProofTest");
      merkleProof = await MerkleProof.deploy();
    });

    it('Compare gas used to trie', async () => {
      let beefyValidatorPubKey = [
        "0x049346ec0021405ec103c2baac8feff9d6fb75851318fb03781edf29f05f2ffeb794c7f5140cce7745a91d45027df5b421342bc2446f39beaf65f705ef864841ed",
        "0x04fe6b333420b90689158643ccad94e62d707de1a80726d53aa04657fec14afd3e441e67f48e61b4e67b4c4ab17713c0737abe7ddad63bb97b1138302e1a776723",
        "0x048c49b70d152e7f9bfbfc4a7c53fb13d8855dbc221e68f7ef734f0af394d86bf1a3b28bf6c6fd814ed8772e41e7a19c2bfc261bff67b46e065d2767a547079139"
      ] 
      const validatorsMerkleTree = createMerkleTree(beefyValidatorPubKey);
      const validatorsLeaf0 = validatorsMerkleTree.getHexLeaves()[0];
      const validator0PubKeyMerkleProof = validatorsMerkleTree.getHexProof(validatorsLeaf0);
      const result = await merkleProof.verifySparseMerkleLeaf(
        validatorsMerkleTree.getHexRoot(),
        validatorsLeaf0,
        0,
        validatorsMerkleTree.getLeaves().length,
        validator0PubKeyMerkleProof 
      )
      // expect(result).to.equal(true)
    })

    it('Large authority gas used', async () => {
      let beefyValidatorPubKey = largeValidatorAddresses;
      const validatorsMerkleTree = createMerkleTree(beefyValidatorPubKey);
      const validatorsLeaf0 = validatorsMerkleTree.getHexLeaves()[0];
      const validator0PubKeyMerkleProof = validatorsMerkleTree.getHexProof(validatorsLeaf0);
      const root = validatorsMerkleTree.getHexRoot()
      const result = await merkleProof.verifySparseMerkleLeaf(
        root,
        validatorsLeaf0,
        0,
        validatorsMerkleTree.getLeaves().length,
        validator0PubKeyMerkleProof 
      )
      // expect(result).to.equal(true)
    })
});

function createMerkleTree(leavesHex) {
  const leavesHashed = leavesHex.map(leaf => keccakFromHexString(leaf));
  const merkleTree = new MerkleTree(leavesHashed, keccak, { sort: false });

  return merkleTree;
}
