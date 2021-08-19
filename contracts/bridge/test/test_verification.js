const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { solidity, MockProvider } = require("ethereum-waffle");
const { keccak } = require("ethereumjs-util");
const {
  signatureSubstrateToEthereum,
  buildCommitment,
  createMerkleTree, mine, catchRevert
} = require("./shared/helpers");
const { BeefyFixture, MessageFixture } = require('./shared/fixtures.js');
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
    "0x00a1537d251a6a4c4effAb76948899061FeA47b9",
  ]
  const [owner, userOne, userTwo, userThree] = provider.getWallets()
  const testPayload = ethers.utils.formatBytes32String("arbitrary-payload");
  const sigs = [BeefyFixture.signature0, BeefyFixture.signature1, BeefyFixture.signature2]
  let lightClientBridge
  let inbound
  let inbound2
  let outbound
  let app

  before(async () => {
    const validatorsMerkleTree = createMerkleTree(beefyValidatorAddresses);
    const validatorsLeaf0 = validatorsMerkleTree.getHexLeaves()[0];
    const validatorsLeaf1 = validatorsMerkleTree.getHexLeaves()[1];
    const validatorsLeaf2 = validatorsMerkleTree.getHexLeaves()[2];
    const validator0PubKeyMerkleProof = validatorsMerkleTree.getHexProof(validatorsLeaf0);
    const validator1PubKeyMerkleProof = validatorsMerkleTree.getHexProof(validatorsLeaf1);
    const validator2PubKeyMerkleProof = validatorsMerkleTree.getHexProof(validatorsLeaf2);
    const proofs = [validator0PubKeyMerkleProof, validator1PubKeyMerkleProof, validator2PubKeyMerkleProof]
    const LightClientBridge = await ethers.getContractFactory("LightClientBridge");
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
      BeefyFixture.signature0,
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
    expect(printBitfield(validata)).to.eq('111')

    await catchRevert(lightClientBridge.createRandomBitfield(lastId), 'Bridge: Block wait period not over');
    await mine(45);

    const randomBitfield = (await lightClientBridge.createRandomBitfield(lastId)); 
    const addrIndex = firstBit(randomBitfield) - 1;
    const bitfield = parseInt(randomBitfield.toString(), 10)

    const proof = {
      "signatures": [sigs[addrIndex]],
      "positions": [addrIndex],  
      "signers": [beefyValidatorAddresses[addrIndex]],
      "signerProofs": [proofs[addrIndex]]
    }
    const completeCommitment = lightClientBridge.completeSignatureCommitment(
      lastId,
      BeefyFixture.commitment,
      proof
    );
    expect(completeCommitment) 
      .to.emit(lightClientBridge, "FinalVerificationSuccessful")
      .withArgs((await completeCommitment).from, lastId)
    const latestMMRRoot = await lightClientBridge.latestMMRRoot();
    expect(latestMMRRoot).to.eq(BeefyFixture.commitment.payload.mmr)

    let laneId = 0
    let nonce = 0
    inbound = await (await ethers.getContractFactory("BasicInboundChannel")).deploy(laneId, nonce, lightClientBridge.address);

    inbound2 = await (await ethers.getContractFactory("BasicInboundChannel")).deploy(1, 0, lightClientBridge.address);
    app = await (await ethers.getContractFactory("MockApp")).deploy();
    outbound = await (await ethers.getContractFactory("BasicOutboundChannel")).deploy();
    await outbound.grantRole("0x7bb193391dc6610af03bd9922e44c83b9fda893aeed61cf64297fb4473500dd1", outbound.signer.address)
  });

  it("should successfully verify a commitment", async () => {
    const polkadotSender = ethers.utils.formatBytes32String('fake-polkadot-address');
    const payloadOne = app.interface.encodeFunctionData("unlock", [polkadotSender, userOne.address, ethers.utils.parseEther("2")]);
    const messageOne = [
      "0x0000000000000000000000000000000000000001",
      app.address,
      inbound.address,
      1,
      payloadOne
    ];
    const payloadTwo = app.interface.encodeFunctionData("unlock", [polkadotSender, userTwo.address, ethers.utils.parseEther("5")]);
    const messageTwo = [
      "0x0000000000000000000000000000000000000002",
      app.address,
      inbound.address,
      2,
      payloadTwo
    ];
    const messages = [messageOne, messageTwo];
    const messagesHash = buildCommitment(messages);
    const payloadThree = app.interface.encodeFunctionData("unlock", [polkadotSender, userOne.address, ethers.utils.parseEther("3")]);
    const messageThree = [
      "0x0000000000000000000000000000000000000001",
      app.address,
      inbound2.address,
      1,
      payloadThree
    ]
    const messages2 = [messageThree]
    const messagesHash2 = buildCommitment(messages2)
    const messageTree = new MerkleTree([messagesHash, messagesHash2], keccak, { duplicateOdd: false, sort: false })
    // messageTree.print()
    const proof = messageTree.getHexProof(messagesHash)
    const proof2 = messageTree.getHexProof(messagesHash2)

    const tx = await inbound.submit(
      messages,
      2,
      proof,
      MessageFixture.mmrLeaf,
      MessageFixture.mmrLeafIndex, // blockNumber + 1
      MessageFixture.mmrLeafCount,
      MessageFixture.mmrProofs.peaks,
      MessageFixture.mmrProofs.siblings
    );
    expect(tx)
      .to.emit(inbound, "MessageDispatched")
      .withArgs(1, true, "0x")
    expect(tx)
      .to.emit(inbound, "MessageDispatched")
      .withArgs(2, false, "0x08c379a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000016696e76616c696420736f75726365206163636f756e7400000000000000000000")
    expect(tx)
      .to.emit(app, "Unlocked")
      .withArgs(polkadotSender, userOne.address, ethers.utils.parseEther("2"))
    expect(tx)

    const tx2 = await inbound2.submit(
      messages2,
      2,
      proof2,
      MessageFixture.mmrLeaf,
      MessageFixture.mmrLeafIndex, // blockNumber + 1
      MessageFixture.mmrLeafCount,
      MessageFixture.mmrProofs.peaks,
      MessageFixture.mmrProofs.siblings
    );
    expect(tx2)
      .to.emit(inbound2, "MessageDispatched")
      .withArgs(1, true, "0x")

    const again = inbound.submit(
          messages,
          2,
          proof,
          MessageFixture.mmrLeaf,
          MessageFixture.mmrLeafIndex, 
          MessageFixture.mmrLeafCount,
          MessageFixture.mmrProofs.peaks,
          MessageFixture.mmrProofs.siblings
      )

    await catchRevert(again, 'Channel: invalid nonce');
  });

  it("should send messages out with the correct event and fields", async function () {
    const tx = await outbound.submit(
      testPayload
    );

    expect(tx)
      .to.emit(outbound, "Message")
      .withArgs(tx.from, 1, testPayload)
  });

  it("should increment nonces correctly", async function () {
    const tx = await outbound.submit(
      testPayload
    );

    const tx2 = await outbound.submit(
      testPayload
    );

    const tx3 = await outbound.submit(
      testPayload
    );

    expect(tx3)
      .to.emit(outbound, "Message")
      .withArgs(tx.from, 4, testPayload)
  });
});

function parseBitfield(s) {
  return parseInt(s, 2)
}

function printBitfield(s) {
  return parseInt(s.toString(), 10).toString(2)
}

function firstBit(x) {
    return Math.floor(
        Math.log(x | 0) / Math.log(2)
    ) + 1;
}
