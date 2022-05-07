const { expect } = require("chai")
const { waffle } = require("hardhat");
const { BigNumber } = require("ethers");
const { bootstrap } = require("./helper/fixture")
const chai = require("chai")
const { solidity } = waffle;

chai.use(solidity)
const log = console.log
const LANE_IDENTIFY_SLOT="0x0000000000000000000000000000000000000000000000000000000000000000"
const LANE_NONCE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000001"
const LANE_MESSAGE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000002"
const overrides = { value: ethers.utils.parseEther("30") }
let ethClient, subClient, bridge

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}


describe("bridge e2e test: verify message/storage proof", () => {

  before(async () => {
  })

  it("bootstrap", async () => {
    const clients = await bootstrap()
    ethClient = clients.ethClient
    subClient = clients.subClient
    bridge = clients.bridge
  })

  it("enroll", async () => {
    await bridge.enroll_relayer()
  })

  it("deposit", async () => {
    await bridge.deposit()
  })

  it("0.1", async function () {
    const nonce = await ethClient.outbound.outboundLaneNonce()
    const tx = await ethClient.outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x",
      overrides
    )
    await expect(tx)
      .to.emit(ethClient.outbound, "MessageAccepted")
      .withArgs(nonce.latest_generated_nonce.add(1), "0x")
  })

  it("0.2", async function () {
    const nonce = await ethClient.outbound.outboundLaneNonce()
    const tx = await ethClient.outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x",
      overrides
    )
    await expect(tx)
      .to.emit(ethClient.outbound, "MessageAccepted")
      .withArgs(nonce.latest_generated_nonce.add(1), "0x")
  })

  it("1", async function () {
    await bridge.relay_eth_header()
    await sleep(4000)
  })

  it("2", async function () {
    await sleep(4000)
    const nonce = await ethClient.outbound.outboundLaneNonce()
    const begin = nonce.latest_received_nonce.add(1)
    const end = nonce.latest_generated_nonce
    const o = await ethClient.outbound.data()
    const data = Array(o.messages.length).fill('0x')
    const tx = await bridge.dispatch_eth_messages(data)
    for (let i=begin; i<=end; i++) {
      await expect(tx)
        .to.emit(subClient.inbound, "MessageDispatched")
        .withArgs(
          i,
          false
        )
    }
  })

  it("3", async function () {
    await bridge.relay_sub_header()
  })

  it("4", async function () {
    const i = await subClient.inbound.data()
    const o = await ethClient.outbound.outboundLaneNonce()
    const tx = await bridge.confirm_eth_messages()
    await expect(tx)
      .to.emit(ethClient.outbound, "MessagesDelivered")
      .withArgs(o.latest_received_nonce.add(1), i.last_delivered_nonce, 0)
  })

  it("5", async function () {
    const nonce = await subClient.outbound.outboundLaneNonce()
    const tx = await subClient.outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x",
      overrides
    )

    await expect(tx)
      .to.emit(subClient.outbound, "MessageAccepted")
      .withArgs(nonce.latest_generated_nonce.add(1), "0x")
  })

  it("6", async function () {
    await bridge.relay_sub_header()
  })

  it("7", async function () {
    const o = await subClient.outbound.data()
    const begin = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce.add(1)
    const data = Array(o.messages.length).fill('0x')
    const tx = await bridge.dispatch_sub_messages(data)
    const end = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce
    for (let i=begin; i<=end; i++) {
      await expect(tx)
        .to.emit(ethClient.inbound, "MessageDispatched")
        .withArgs(
          i,
          false
        )
    }
  })

  it("8", async function () {
    const nonce = await subClient.outbound.outboundLaneNonce()
    const tx = await subClient.outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x",
      overrides
    )

    await expect(tx)
      .to.emit(subClient.outbound, "MessageAccepted")
      .withArgs(nonce.latest_generated_nonce.add(1), "0x")
  })

  it("9", async function () {
    await bridge.relay_sub_header()
  })

  it("10", async function () {
    const o = await subClient.outbound.data()
    const begin = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce.add(1)
    let signer = ethClient.get_signer(1)
    const data = Array(o.messages.length).fill('0x')
    const tx = await bridge.dispatch_sub_messages(data, signer)
    const end = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce
    for (let i=begin; i<=end; i++) {
      await expect(tx)
        .to.emit(ethClient.inbound, "MessageDispatched")
        .withArgs(
          i,
          false
        )
    }
  })

  it("11", async function () {
    await bridge.relay_eth_header()
    await sleep(3000)
  })

  it("12", async function () {
    await sleep(3000)
    const i = await ethClient.inbound.data()
    const o = await subClient.outbound.outboundLaneNonce()
    const tx = await bridge.confirm_sub_messages()
    await expect(tx)
      .to.emit(subClient.outbound, "MessagesDelivered")
      .withArgs(o.latest_received_nonce.add(1), i.last_delivered_nonce, 0)
  })
})
