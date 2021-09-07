const { BigNumber } = require("ethers");
const {
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

describe("Light Client collateral tests", function () {

  it("should slash the relayer who complete commitment late", async () => {
    totalNumberOfValidators = 3
    totalNumberOfSignatures = 3
    const fixture = await createBeefyValidatorFixture(
      totalNumberOfValidators
    )
    const numOfGuards = 3;
    const guards = fixture.validatorAddresses.slice(0, numOfGuards)
    const LightClientBridge = await ethers.getContractFactory("LightClientBridge");
    const crab = beefyFixture.commitment.payload.network
    const vault = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"

    beefyLightClient = await LightClientBridge.deploy(
      crab,
      vault,
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
    const maliciousCommitmentHash = "0x0000000000000000000000000000000000000000000000000000000000000000"
    const domainSeparator = await beefyLightClient.domainSeparator();
    const allMaliciousProofs = await createAllValidatorProofs(maliciousCommitmentHash, fixture);
    let overrides = {
        value: ethers.utils.parseEther("4")
    };
    const newSigTxPromise = beefyLightClient.newSignatureCommitment(
      maliciousCommitmentHash,
      initialBitfield,
      allMaliciousProofs[firstPosition].signature,
      firstPosition,
      allMaliciousProofs[firstPosition].address,
      allMaliciousProofs[firstPosition].proof,
      overrides
    )
    await newSigTxPromise.should.be.fulfilled
    const lastId = (await beefyLightClient.currentId()).sub(BigNumber.from(1));
    await mine(20);
    const cleanTxPromise = beefyLightClient.cleanExpiredCommitment(lastId)
    await cleanTxPromise.should.be.rejected

    await mine(235)
    const cleanTxPromise2 = beefyLightClient.cleanExpiredCommitment(lastId)
    await cleanTxPromise2.should.be.fulfilled
    const slash = (await ethers.provider.getBalance(vault)).toString()
    expect(slash).to.eq("4000000000000000000")
  })

});
