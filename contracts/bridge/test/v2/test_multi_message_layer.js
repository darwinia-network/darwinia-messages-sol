const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");

chai.use(solidity);
const log = console.log
const thisChainPos = 0
const thisLanePos = 0
const bridgedChainPos = 1
const bridgedLanePos = 1
let owner, addr1, addr2
let outbound, inbound
let outboundData, inboundData

const send_message = async (nonce) => {
    let overrides = {
        value: ethers.utils.parseEther("1")
    }
    const tx = await outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x",
      overrides
    )
    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(nonce)
    await logNonce()
}

const logNonce = async () => {
  const out = await outbound.outboundLaneNonce()
  const iin = await inbound.inboundLaneNonce()
  log(`(${out.latest_received_nonce}, ${out.latest_generated_nonce}]                                            ->     (${iin.last_confirmed_nonce}, ${iin.last_delivered_nonce}]`)
}

const receive_messages_proof = async (addr, nonce) => {
    laneData = await outbound.data()
    const tx = await inbound.connect(addr).receive_messages_proof(laneData, "0x")
    const n = await inbound.inboundLaneNonce()
    const size = n.last_delivered_nonce - nonce
    for (let i = 0; i<size; i++) {
      await expect(tx)
        .to.emit(inbound, "MessageDispatched")
        .withArgs(thisChainPos, thisLanePos, bridgedChainPos, bridgedLanePos, nonce+i, false, "0x4c616e653a204d65737361676543616c6c52656a6563746564")
    }
    await logNonce()
}

const receive_messages_delivery_proof = async (addr, begin, end) => {
    laneData = await inbound.data()
    const tx = await outbound.connect(addr).receive_messages_delivery_proof(laneData, "0x")
    const d = await tx.wait();
    await expect(tx)
      .to.emit(outbound, "MessagesDelivered")
      .withArgs(begin, end, 0)
    await expect(tx)
      .to.emit(outbound, "RelayerReward")
      .withArgs(addr1.address, ethers.utils.parseEther("3.3"))
    await expect(tx)
      .to.emit(outbound, "RelayerReward")
      .withArgs(addr2.address, ethers.utils.parseEther("1.8"))
    await expect(tx)
      .to.emit(outbound, "RelayerReward")
      .withArgs(addr2.address, ethers.utils.parseEther("0.9"))
    await logNonce()
}

describe("multi message relay tests", () => {

  before(async () => {
    [owner, addr1, addr2] = await ethers.getSigners()
    const MockLightClient = await ethers.getContractFactory("MockLightClient")
    const lightClient = await MockLightClient.deploy()
    const OutboundLane = await ethers.getContractFactory("OutboundLane")
    outbound = await OutboundLane.deploy(lightClient.address, thisChainPos, thisLanePos, bridgedChainPos, bridgedLanePos, 1, 0, 0)
    await outbound.grantRole("0x7bb193391dc6610af03bd9922e44c83b9fda893aeed61cf64297fb4473500dd1", owner.address)
    const InboundLane = await ethers.getContractFactory("InboundLane")
    inbound = await InboundLane.deploy(lightClient.address, bridgedChainPos, bridgedLanePos, thisChainPos, thisLanePos, 0, 0)
    log(" out bound lane                                   ->      in bound lane")
    log("(latest_received_nonce, latest_generated_nonce]   ->     (last_confirmed_nonce, last_delivered_nonce]")
  })

  it("0", async function () {
    await send_message(1)
  })

  it("1", async function () {
    await receive_messages_proof(addr1, 1)
  })

  it("2", async function () {
    await send_message(2)
  })

  it("3", async function () {
    await receive_messages_proof(addr2, 2)
  })


  it("4", async function () {
    await send_message(3)
  })

  it("5", async function () {
    await receive_messages_proof(addr2, 3)
  })

  it("6", async function () {
    await send_message(4)
  })

  it("7", async function () {
    await send_message(5)
  })

  it("8", async function () {
    await receive_messages_proof(addr1, 5)
  })

  it("9", async function () {
    await send_message(6)
  })

  it("10", async function () {
    await receive_messages_proof(addr2, 6)
  })

  it("11", async function () {
    await receive_messages_delivery_proof(addr1, 1, 6)
  })
})
