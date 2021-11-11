const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");

chai.use(solidity);

describe("OutboundLane tests", () => {
  let outbound
  let inbound
  let outboundData
  let inboundData

  before(async () => {
    const [owner] = await ethers.getSigners();
    const MockLightClient = await ethers.getContractFactory("MockLightClient")
    const lightClient = await MockLightClient.deploy()
    const OutboundLane = await ethers.getContractFactory("OutboundLane")
    outbound = await OutboundLane.deploy(lightClient.address, 0, 1, 0, 1, 0, 0)
    await outbound.grantRole("0x7bb193391dc6610af03bd9922e44c83b9fda893aeed61cf64297fb4473500dd1", owner.address)
    const InboundLane = await ethers.getContractFactory("InboundLane")
    inbound = await InboundLane.deploy(lightClient.address, 1, 0, 0, 0, 0)
  });

  it("0", async function () {
    const tx = await outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x"
    )
    const key = await outbound.encodeMessageKey(1)
    const msg = await outbound.messages(key)
    const nonce = await outbound.outboundLaneNonce();

    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(1, 0, 1)

    await expect(tx)
      .to.emit(outbound, "MessagePruned")
      .withArgs(1, 0, 1)

  });

  it("1", async function () {
    const tx = await outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x"
    )

    const key = await outbound.encodeMessageKey(2)
    const msg = await outbound.messages(key)
    const nonce = await outbound.outboundLaneNonce();

    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(1, 0, 2)

    await expect(tx)
      .to.emit(outbound, "MessagePruned")
      .withArgs(1, 0, 1)
  });

  it("2", async function () {
    outboundData = await outbound.data()
    const tx = await inbound.receive_messages_proof(outboundData, "0x0000000000000000000000000000000000000000000000000000000000000000", "0x")
    await expect(tx)
      .to.emit(inbound, "MessageDispatched")
      .withArgs(1, 0, 1, false, "0x4c616e653a204d65737361676543616c6c52656a6563746564")
    await expect(tx)
      .to.emit(inbound, "MessageDispatched")
      .withArgs(1, 0, 2, false, "0x4c616e653a204d65737361676543616c6c52656a6563746564")
  });

  it("3", async function () {
    inboundData = await inbound.data()
    const tx = await outbound.receive_messages_delivery_proof("0x0000000000000000000000000000000000000000000000000000000000000000", inboundData, "0x")
    await expect(tx)
      .to.emit(outbound, "MessagesDelivered")
      .withArgs(1, 0, 1, 2, 0)
  });

});
