const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { solidity, MockProvider, deployContract } = require("ethereum-waffle");
const {
  signatureSubstrateToEthereum,
  buildCommitment,
  createMerkleTree, mine, catchRevert
} = require("./shared/helpers");
const { BeefyFixture } = require('./shared/fixtures.js');
const chai = require("chai");
const MerkleTree = require("merkletreejs").MerkleTree;

chai.use(solidity);

describe("Verification tests", () => {
  const provider = new MockProvider({
    ganacheOptions: {
      hardfork: 'istanbul',
      mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
      gasLimit: 9999999,
    },
  })

  const beefyValidatorAddresses = [
    "0xB13f16A6772C5A0b37d353C07068CA7B46297c43",
    "0xcC5E48BEb33b83b8bD0D9d9A85A8F6a27C51F5C5",
  ]
  const [owner, userOne, userTwo, userThree] = provider.getWallets()
  let lightClientBridge

  beforeEach(async () => {

    const validatorsMerkleTree = createMerkleTree(beefyValidatorAddresses);
    const validatorsLeaf0 = validatorsMerkleTree.getHexLeaves()[0];
    const validatorsLeaf1 = validatorsMerkleTree.getHexLeaves()[1];
    const validator0PubKeyMerkleProof = validatorsMerkleTree.getHexProof(validatorsLeaf0);
    const validator1PubKeyMerkleProof = validatorsMerkleTree.getHexProof(validatorsLeaf1);
    const LightClientBridge = await ethers.getContractFactory("LightClientBridge");
    MerkleTree.print(validatorsMerkleTree)
    lightClientBridge = await LightClientBridge.deploy(
      0,
      validatorsMerkleTree.getLeaves().length,
      validatorsMerkleTree.getHexRoot()
    );
    expect(await lightClientBridge.checkValidatorInSet(beefyValidatorAddresses[0], 0, validator0PubKeyMerkleProof)).to.be.true
    expect(await lightClientBridge.checkValidatorInSet(beefyValidatorAddresses[1], 1, validator1PubKeyMerkleProof)).to.be.true
    const newCommitment = lightClientBridge.newSignatureCommitment(
      BeefyFixture.commitmentHash,
      BeefyFixture.bitfield,
      signatureSubstrateToEthereum(BeefyFixture.signature0),
      0,
      beefyValidatorAddresses[0],
      validator0PubKeyMerkleProof
    );
    await expect(newCommitment).to.not.be.reverted
    expect(newCommitment)
      .to.emit(lightClientBridge, "InitialVerificationSuccessful")
      .withArgs((await newCommitment).from,(await newCommitment).blockNumber, 0)

    const currentId = await lightClientBridge.currentId()
    expect(currentId).to.equal(1)
    const lastId = currentId.sub(1);

    const validata = await lightClientBridge.validatorBitfield(lastId);
    expect(printBitfield(validata)).to.eq('11')

    const completeCommitmentTooEarly = lightClientBridge.completeSignatureCommitment(
      lastId,
      BeefyFixture.commitment,
      [signatureSubstrateToEthereum(BeefyFixture.signature1)],
      [1],
      beefyValidatorAddresses,
      [validator0PubKeyMerkleProof, validator1PubKeyMerkleProof]
    );
    await catchRevert(completeCommitmentTooEarly, 'Bridge: Block wait period not over');
    await mine(45);

    const completeCommitment = lightClientBridge.completeSignatureCommitment(
      lastId,
      BeefyFixture.commitment,
      [signatureSubstrateToEthereum(BeefyFixture.signature1)],
      [1],
      beefyValidatorAddresses,
      [validator0PubKeyMerkleProof, validator1PubKeyMerkleProof]
    );
    console.log(await completeCommitment)
    expect(completeCommitment) 
      .to.emit(lightClientBridge, "FinalVerificationSuccessful")
      .withArgs((await completeCommitment).from, BeefyFixture.commitmentHash, lastId)
    console.log(await lightClientBridge.latestMMRRoot());

    // this.channel = await BasicInboundChannel.new(this.lightClientBridge.address,
    //   { from: owner }
    // );
    // this.app = await MockApp.new();
  });

  it("should successfully verify a commitment", async () => {
    // // TODO finish this test
    // return

    // const abi = this.app.abi;
    // const iChannel = new ethers.utils.Interface(abi);
    // const polkadotSender = ethers.utils.formatBytes32String('fake-polkadot-address');
    // const unlockFragment = iChannel.functions['unlock(bytes32,address,uint256)'];
    // const payloadOne = iChannel.encodeFunctionData(unlockFragment, [polkadotSender, userTwo, 2]);
    // const messageOne = {
    //   target: this.ethApp.address,
    //   nonce: 1,
    //   payload: payloadOne
    // };
    // const payloadTwo = iChannel.encodeFunctionData(unlockFragment, [polkadotSender, userThree, 5]);
    // const messageTwo = {
    //   target: this.ethApp.address,
    //   nonce: 2,
    //   payload: payloadTwo
    // };
    // const messages = [messageOne, messageTwo];
    // const commitment = buildCommitment(messages);
    // const tx = await this.inbound.submit(
    //   messages,
    //   commitment,
    //   fixture.leaf,
    //   fixture.leafIndex,
    //   fixture.leafCount,
    //   fixture.proofs,
    //   { from: userOne }
    // );
    // console.log(tx);
  });
});

function parseBitfield(s) {
  return parseInt(s, 2)
}

function printBitfield(s) {
  return parseInt(s.toString(), 10).toString(2)
}
