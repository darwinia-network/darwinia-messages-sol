const { BigNumber } = require("ethers");
const {
  deployBeefyLightClient,
  mine, printTxPromiseGas
} = require("./shared/helpers");

const {
  createBeefyValidatorFixture,
  createRandomPositions,
  createAllValidatorProofs,
  createCompleteValidatorProofs,
  createAllGuardProofs
} = require("./shared/beefy-helpers");
const beefyFixture = require('./shared/beefy-fixture-data.json');

require("chai")
  .use(require("chai-as-promised"))
  .should();

const { expect } = require("chai");

describe("Light Client Gas Usage", function () {

  const testCases = [
    {
      totalNumberOfValidators: 10,
      totalNumberOfSignatures: 10,
    },
    {
      totalNumberOfValidators: 100,
      totalNumberOfSignatures: 100,
    },
    {
      totalNumberOfValidators: 150,
      totalNumberOfSignatures: 101,
    },
    // {
    //   totalNumberOfValidators: 257,
    //   totalNumberOfSignatures: 257,
    // },
    // {
    //   totalNumberOfValidators: 1000,
    //   totalNumberOfSignatures: 1000,
    //   fail: true
    // },
    // {
    //   totalNumberOfValidators: 1000,
    //   totalNumberOfSignatures: 1000,
    // },
    // {
    //   totalNumberOfValidators: 1000,
    //   totalNumberOfSignatures: 667,
    // },
  ]

  for (const testCase of testCases) {
    it(`runs full flow with ${testCase.totalNumberOfValidators} validators and ${testCase.totalNumberOfSignatures} signers with the complete transaction ${testCase.fail ? 'failing' : 'succeeding'}`,
      async function () {
        this.timeout(1000 * 65);
        await runFlow(testCase.totalNumberOfValidators, testCase.totalNumberOfSignatures, testCase.fail)
      });
  }

  const runFlow = async function (totalNumberOfValidators, totalNumberOfSignatures, fail) {
    console.log(`Running flow with ${totalNumberOfValidators} validators and ${totalNumberOfSignatures} signatures with the complete transaction ${fail ? 'failing' : 'succeeding'}: `)

    const fixture = await createBeefyValidatorFixture(
      totalNumberOfValidators
    )
    const numOfGuards = 3;
    const guards = fixture.validatorAddresses.slice(0, numOfGuards)
    // console.log(0, guards)
    // console.log(1, fixture.validatorAddresses)
    const LightClientBridge = await ethers.getContractFactory("LightClientBridge");
    const crab = beefyFixture.commitment.payload.network
    beefyLightClient = await LightClientBridge.deploy(
      crab,
      guards,
      2,
      0,
      totalNumberOfValidators,
      fixture.root,
    );

    const initialBitfieldPositions = await createRandomPositions(totalNumberOfSignatures, totalNumberOfValidators)

    const firstPosition = initialBitfieldPositions[0]

    const initialBitfield = await beefyLightClient.createInitialBitfield(
      initialBitfieldPositions, totalNumberOfValidators
    );

    const commitmentHash = await beefyLightClient.createCommitmentHash(beefyFixture.commitment);

    const domainSeparator = await beefyLightClient.domainSeparator();

    const allValidatorProofs = await createAllValidatorProofs(commitmentHash, fixture);

    const allGuardProofs = await createAllGuardProofs(commitmentHash, fixture, domainSeparator, guards)

    const newSigTxPromise = beefyLightClient.newSignatureCommitment(
      commitmentHash,
      initialBitfield,
      allValidatorProofs[firstPosition].signature,
      firstPosition,
      allValidatorProofs[firstPosition].address,
      allValidatorProofs[firstPosition].proof,
    )
    printTxPromiseGas("newSignatureCommitment", await newSigTxPromise)
    await newSigTxPromise.should.be.fulfilled

    const lastId = (await beefyLightClient.currentId()).sub(BigNumber.from(1));

    await mine(45);

    const completeValidatorProofs = await createCompleteValidatorProofs(lastId, beefyLightClient, allValidatorProofs);

    const completeSigTxPromise = beefyLightClient.completeSignatureCommitment(
      fail ? 99 : lastId,
      beefyFixture.commitment,
      completeValidatorProofs,
      allGuardProofs
    )
    await printTxPromiseGas("completeSignatureCommitment", await completeSigTxPromise)
    if (fail) {
      await completeSigTxPromise.should.be.rejected
    } else {
      await completeSigTxPromise.should.be.fulfilled
      latestMMRRoot = await beefyLightClient.latestMMRRoot()
      expect(latestMMRRoot).to.eq(beefyFixture.commitment.payload.mmr)
    }
  }

});
