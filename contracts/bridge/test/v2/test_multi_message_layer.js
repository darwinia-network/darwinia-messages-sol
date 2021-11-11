const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");

chai.use(solidity);
const log = console.log
const thisChainPos = 0
const bridgedChainPos = 1
const lanePos = 0
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
      .withArgs(bridgedChainPos, lanePos, nonce)
    await logNonce()
}

const logNonce = async () => {
  const out = await outbound.outboundLaneNonce()
  const iin = await inbound.inboundLaneNonce()
  log(`(${out.latest_received_nonce}, ${out.latest_generated_nonce}]                                            ->     (${iin.last_confirmed_nonce}, ${iin.last_delivered_nonce}]`)
}

const receive_messages_proof = async (nonce) => {
    laneData = await outbound.data()
    const tx = await inbound.connect(addr2).receive_messages_proof(laneData, "0x0000000000000000000000000000000000000000000000000000000000000000", "0x")
    const n = await inbound.inboundLaneNonce()
    const size = n.last_delivered_nonce - nonce
    for (let i = 0; i<size; i++) {
      await expect(tx)
        .to.emit(inbound, "MessageDispatched")
        .withArgs(bridgedChainPos, lanePos, nonce+i, false, "0x4c616e653a204d65737361676543616c6c52656a6563746564")
    }
    await logNonce()
}

const receive_messages_delivery_proof = async (begin, end) => {
    laneData = await inbound.data()
    const tx = await outbound.connect(addr1).receive_messages_delivery_proof("0x0000000000000000000000000000000000000000000000000000000000000000", laneData, "0x")
    await expect(tx)
      .to.emit(outbound, "MessagesDelivered")
      .withArgs(bridgedChainPos, lanePos, begin, end, 0)
    await expect(tx)
      .to.emit(outbound, "RelayerReward")
      .withArgs(addr1.address, ethers.utils.parseEther("0.1"))
    await expect(tx)
      .to.emit(outbound, "RelayerReward")
      .withArgs(addr2.address, ethers.utils.parseEther("0.9"))
    await logNonce()
}

//   out bound lane                                    ->           in bound lane
//   (latest_received_nonce, latest_generated_nonce]   ->     (last_confirmed_nonce, last_delivered_nonce]
//0  (0, 1]   #send_message                            ->     (0, 0]
//1  (0, 1]                                            ->     (0, 1]  #receive_messages_proof
//2  (1, 1]   #receive_messages_delivery_proof         ->     (0, 1]
//3  (1, 1]                                            ->     (1, 1]  #receive_messages_proof
describe("multi message relay tests", () => {

  before(async () => {
    [owner, addr1, addr2] = await ethers.getSigners()
    const MockLightClient = await ethers.getContractFactory("MockLightClient")
    const lightClient = await MockLightClient.deploy()
    const OutboundLane = await ethers.getContractFactory("OutboundLane")
    outbound = await OutboundLane.deploy(lightClient.address, thisChainPos, bridgedChainPos, lanePos, 1, 0, 0)
    await outbound.grantRole("0x7bb193391dc6610af03bd9922e44c83b9fda893aeed61cf64297fb4473500dd1", owner.address)
    const InboundLane = await ethers.getContractFactory("InboundLane")
    inbound = await InboundLane.deploy(lightClient.address, bridgedChainPos, thisChainPos, lanePos, 0, 0)
    log(" out bound lane                                   ->      in bound lane")
    log("(latest_received_nonce, latest_generated_nonce]   ->     (last_confirmed_nonce, last_delivered_nonce]")
  })

  it("0", async function () {
    await send_message(1)
  })

  it("1", async function () {
    await receive_messages_proof(1)
  })

  it("2", async function () {
    const d = await inbound.data()
    await receive_messages_delivery_proof(1, 1)
  })

  it("3", async function () {
    await receive_messages_proof(1)
  })

  it("4", async function () {
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
      .withArgs(bridgedChainPos, lanePos, 2)
    await expect(tx)
      .to.emit(outbound, "MessagePruned")
      .withArgs(bridgedChainPos, lanePos, 2)
    await logNonce()
  })
})
