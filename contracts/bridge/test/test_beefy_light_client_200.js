const { BigNumber } = require("ethers");
const {
  mine, printTxPromiseGas,
  createBeefyValidatorFixture,
  createRandomPositions,
  createAllValidatorProofs,
  createCompleteValidatorProofs,
  createSingleValidatorProof,
} = require("./shared/helpers");
const beefyFixture = require('./shared/beefy-data.json');

require("chai")
  .use(require("chai-as-promised"))
  .should();

const { expect } = require("chai");

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

describe("Light Client Gas Usage", function () {

  const testCases = [
    {
      totalNumberOfValidators: 100,
      totalNumberOfSignatures: 67,
    },
    // {
    //   totalNumberOfValidators: 110,
    //   totalNumberOfSignatures: 74,
    // },
    // {
    //   totalNumberOfValidators: 120,
    //   totalNumberOfSignatures: 81,
    // },
    // {
    //   totalNumberOfValidators: 130,
    //   totalNumberOfSignatures: 87,
    // },
    // {
    //   totalNumberOfValidators: 140,
    //   totalNumberOfSignatures: 94,
    // },
    // {
    //   totalNumberOfValidators: 150,
    //   totalNumberOfSignatures: 101,
    // },
    // {
    //   totalNumberOfValidators: 160,
    //   totalNumberOfSignatures: 107,
    // },
    // {
    //   totalNumberOfValidators: 170,
    //   totalNumberOfSignatures: 114,
    // },
    // {
    //   totalNumberOfValidators: 180,
    //   totalNumberOfSignatures: 121,
    // },
    // {
    //   totalNumberOfValidators: 190,
    //   totalNumberOfSignatures: 127,
    // },
    // {
    //   totalNumberOfValidators: 200,
    //   totalNumberOfSignatures: 134,
    // },
  ]

  for (const testCase of testCases) {
    it(`runs full flow with ${testCase.totalNumberOfValidators} validators and ${testCase.totalNumberOfSignatures} signers with the complete transaction succeeding`,
      async function () {
        this.timeout(1000 * 1200);
        await runFlow(testCase.totalNumberOfValidators, testCase.totalNumberOfSignatures)
      });
  }

  const runFlow = async function (totalNumberOfValidators, totalNumberOfSignatures) {
    console.log(`Running flow with ${totalNumberOfValidators} validators and ${totalNumberOfSignatures} signatures with the complete transaction succeeding: `)

    const fixture = await createBeefyValidatorFixture(
      totalNumberOfValidators
    )
    const LightClientBridge = await ethers.getContractFactory("DarwiniaLightClient");
    const vault = "0x0000000000000000000000000000000000000000"
    beefyLightClient = await LightClientBridge.deploy(
      vault,
      0,
      totalNumberOfValidators,
      fixture.root,
    );

    const initialBitfieldPositions = await createRandomPositions(totalNumberOfSignatures, totalNumberOfValidators)

    const firstPosition = initialBitfieldPositions[0]

    const initialBitfield = await beefyLightClient.createInitialBitfield(
      initialBitfieldPositions
    );

    const commitmentHash = await beefyLightClient.hash(beefyFixture.commitment);

    const allValidatorProofs = await createAllValidatorProofs(commitmentHash, fixture);

    const firstProof = await createSingleValidatorProof(firstPosition, fixture)

    let overrides = {
        value: ethers.utils.parseEther("4")
    };

    const singleProof = {
        signature: allValidatorProofs[firstPosition].signature,
        position: firstPosition,
        signer: allValidatorProofs[firstPosition].address,
        proof: firstProof,
    }
    const newSigTxPromise = beefyLightClient.newSignatureCommitment(
      commitmentHash,
      initialBitfield,
      singleProof,
      overrides
    )
    printTxPromiseGas("1-step", await newSigTxPromise)
    await newSigTxPromise.should.be.fulfilled

    await mine(20);
    // await sleep(1000 * 100)

    const lastId = (await beefyLightClient.currentId()).sub(BigNumber.from(1));

    const completeValidatorProofs = await createCompleteValidatorProofs(lastId, beefyLightClient, allValidatorProofs, fixture);

    const completeSigTxPromise = beefyLightClient.completeSignatureCommitment(
      lastId,
      beefyFixture.commitment,
      completeValidatorProofs
    )
    await printTxPromiseGas("2-step", await completeSigTxPromise)
    await completeSigTxPromise.should.be.fulfilled
  }

});
