const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const { GuardFixture } = require('./shared/fixtures.js');
const chai = require("chai");

chai.use(solidity);

describe("Guard tests", () => {
  let lightClientBridge

  before(async () => {
    const LightClientBridge = await ethers.getContractFactory("contracts/ethereum/v2/LightClientBridge.sol:LightClientBridge");
    const crab = GuardFixture.network
    const vault = "0x0000000000000000000000000000000000000000"
    lightClientBridge = await LightClientBridge.deploy(
      crab,
      vault,
      GuardFixture.guards,
      2,
      0,
      0,
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    );

  });

  it("should add new guard set correctly", async function () {
    let newGuard = "0xB13f16A6772C5A0b37d353C07068CA7B46297c43"
    let newThreshold = 3
    const tx = await lightClientBridge.addGuardWithThreshold(
      newGuard,
      newThreshold,
      GuardFixture.signatures0
    )
    expect(tx)
      .to.emit(lightClientBridge, "AddedGuard")
      .withArgs(newGuard)

    expect(tx)
      .to.emit(lightClientBridge, "ChangedThreshold")
      .withArgs(newThreshold)
  });

  it("should remove the guard set correctly", async function () {
    let prevGuard = "0x0000000000000000000000000000000000000001"
    let rmGuard = "0xB13f16A6772C5A0b37d353C07068CA7B46297c43"
    let newThreshold = 2
    const tx = await lightClientBridge.removeGuard(
      prevGuard,
      rmGuard,
      newThreshold,
      GuardFixture.signatures1
    )
    expect(tx)
      .to.emit(lightClientBridge, "RemovedGuard")
      .withArgs(rmGuard)

    expect(tx)
      .to.emit(lightClientBridge, "ChangedThreshold")
      .withArgs(newThreshold)
  });

  it("should swap the guard set correctly", async function () {
    let prevGuard = "0x0000000000000000000000000000000000000001"
    let oldGuard = "0xE78399B095Df195f10b56724DD22AA88fC295B4a"
    let newGuard = "0xB13f16A6772C5A0b37d353C07068CA7B46297c43"
    const tx = await lightClientBridge.swapGuard(
      prevGuard,
      oldGuard,
      newGuard,
      GuardFixture.signatures2
    )
    expect(tx)
      .to.emit(lightClientBridge, "RemovedGuard")
      .withArgs(oldGuard)

    expect(tx)
      .to.emit(lightClientBridge, "AddedGuard")
      .withArgs(newGuard)
  });

  it("should change the guard threshold correctly", async function () {
    let newThreshold = 3
    const tx = await lightClientBridge.changeThreshold(
      newThreshold,
      GuardFixture.signatures3
    )
    expect(tx)
      .to.emit(lightClientBridge, "ChangedThreshold")
      .withArgs(newThreshold)
  });

});
