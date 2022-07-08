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
const overrides = { value: ethers.utils.parseEther("0.0001"), gasPrice: 1000000000 }
const bsc_overrides = { value: ethers.utils.parseEther("0.01"), gasPrice: 10000000000 }
let ethClient, subClient, bridge
let eth_signer, bsc_signer, source
const target = "0x0000000000000000000000000000000000000000"
const encoded = "0x"

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

const build_land_data = (laneData) => {
    let data = {
      latest_received_nonce: laneData.latest_received_nonce,
      messages: []
    }
    for (let i = 0; i< laneData.messages.length; i++) {
      let message = {
        encoded_key: laneData.messages[i].encoded_key,
        payload: {
          source,
          target,
          encoded,
        }
      }
      data.messages.push(message)
    }
    return data
}

describe("bridge e2e test: verify message/storage proof", () => {

  before(async () => {
  })

  it("bootstrap", async () => {
    const clients = await bootstrap()
    ethClient = clients.ethClient
    bscClient = clients.bscClient
    subClient = clients.subClient
    bridge = clients.bridge

    eth_signer = ethClient.get_signer(0)
    bsc_signer = bscClient.get_signer(0)
    source = eth_signer.address
  })

  it.skip("eth enroll", async () => {
    // await bridge.enroll_relayer()
    await ethClient.feeMarket.connect(eth_signer).enroll(
      "0x0000000000000000000000000000000000000001",
      ethers.utils.parseEther("0.0001"),
      {
        value: ethers.utils.parseEther("0.0001"),
        gasPrice: 1000000000,
        gasLimit: 300000
      }
    )
  })

  it.skip("bsc enroll", async () => {
    await bscClient.feeMarket.connect(bsc_signer).enroll(
      "0x0000000000000000000000000000000000000001",
      ethers.utils.parseEther("0.01"),
      {
        value: ethers.utils.parseEther("0.01"),
        gasPrice: 10000000000,
        gasLimit: 300000
      }
    )
  })

  it.skip("deposit", async () => {
    await bridge.deposit()
  })

  it.skip("0.1", async function () {
    const nonce = await ethClient.outbound.outboundLaneNonce()
    const tx = await ethClient.outbound.send_message(
      target,
      encoded,
      overrides
    )
    await expect(tx)
      .to.emit(ethClient.outbound, "MessageAccepted")
      .withArgs(
        nonce.latest_generated_nonce.add(1),
        source,
        target,
        encoded
      )
  })

  it.skip("0.2", async function () {
    const nonce = await ethClient.outbound.outboundLaneNonce()
    const tx = await ethClient.outbound.send_message(
      target,
      encoded,
      overrides
    )
    await expect(tx)
      .to.emit(ethClient.outbound, "MessageAccepted")
      .withArgs(
        nonce.latest_generated_nonce.add(1),
        source,
        target,
        encoded
      )
  })

  it.skip("1.1", async function () {
    await bridge.relay_eth_header()
  })

  it.skip("1.2", async function () {
    await bridge.relay_eth_execution_payload()
  })

  it.skip("1.3", async function () {
    const nonce = await ethClient.outbound.outboundLaneNonce()
    const begin = nonce.latest_received_nonce.add(1)
    const end = nonce.latest_generated_nonce
    const o = await ethClient.outbound.data()
    let data = build_land_data(o)
    const tx = await bridge.dispatch_eth_messages(data)
    log(tx)
    for (let i=begin; i<=end; i++) {
      await expect(tx)
        .to.emit(subClient.eth.inbound, "MessageDispatched")
        .withArgs(
          i,
          false
        )
    }
  })

  it.skip("2.1", async function () {
    const nonce = await bscClient.outbound.outboundLaneNonce()
    const tx = await bscClient.outbound.send_message(
      target,
      encoded,
      bsc_overrides
    )
    await expect(tx)
      .to.emit(bscClient.outbound, "MessageAccepted")
      .withArgs(
        nonce.latest_generated_nonce.add(1),
        source,
        target,
        encoded
      )
  })

  it.skip("2.2", async function () {
    await bridge.relay_bsc_header()
  })

  it("2.3", async function () {
    const nonce = await bscClient.outbound.outboundLaneNonce()
    const begin = nonce.latest_received_nonce.add(1)
    const end = nonce.latest_generated_nonce
    const o = await bscClient.outbound.data()
    let data = build_land_data(o)
    const tx = await bridge.dispatch_bsc_messages(data)
    log(tx)
    for (let i=begin; i<=end; i++) {
      await expect(tx)
        .to.emit(subClient.bsc.inbound, "MessageDispatched")
        .withArgs(
          i,
          false
        )
    }
  })

  // it("3", async function () {
  //   await bridge.relay_sub_header()
  // })

  // it("4", async function () {
  //   const i = await subClient.inbound.data()
  //   const o = await ethClient.outbound.outboundLaneNonce()
  //   const tx = await bridge.confirm_eth_messages()
  //   await expect(tx)
  //     .to.emit(ethClient.outbound, "MessagesDelivered")
  //     .withArgs(o.latest_received_nonce.add(1), i.last_delivered_nonce, 0)
  // })

  // it("5", async function () {
  //   const nonce = await subClient.outbound.outboundLaneNonce()
  //   const tx = await subClient.outbound.send_message(
  //     "0x0000000000000000000000000000000000000000",
  //     "0x",
  //     overrides
  //   )

  //   await expect(tx)
  //     .to.emit(subClient.outbound, "MessageAccepted")
  //     .withArgs(nonce.latest_generated_nonce.add(1), "0x")
  // })

  // it("6", async function () {
  //   await bridge.relay_sub_header()
  // })

  // it("7", async function () {
  //   const o = await subClient.outbound.data()
  //   const begin = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce.add(1)
  //   const data = Array(o.messages.length).fill('0x')
  //   const tx = await bridge.dispatch_sub_messages(data)
  //   const end = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce
  //   for (let i=begin; i<=end; i++) {
  //     await expect(tx)
  //       .to.emit(ethClient.inbound, "MessageDispatched")
  //       .withArgs(
  //         i,
  //         false
  //       )
  //   }
  // })

  // it("8", async function () {
  //   const nonce = await subClient.outbound.outboundLaneNonce()
  //   const tx = await subClient.outbound.send_message(
  //     "0x0000000000000000000000000000000000000000",
  //     "0x",
  //     overrides
  //   )

  //   await expect(tx)
  //     .to.emit(subClient.outbound, "MessageAccepted")
  //     .withArgs(nonce.latest_generated_nonce.add(1), "0x")
  // })

  // it("9", async function () {
  //   await bridge.relay_sub_header()
  // })

  // it("10", async function () {
  //   const o = await subClient.outbound.data()
  //   const begin = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce.add(1)
  //   let signer = ethClient.get_signer(1)
  //   const data = Array(o.messages.length).fill('0x')
  //   const tx = await bridge.dispatch_sub_messages(data, signer)
  //   const end = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce
  //   for (let i=begin; i<=end; i++) {
  //     await expect(tx)
  //       .to.emit(ethClient.inbound, "MessageDispatched")
  //       .withArgs(
  //         i,
  //         false
  //       )
  //   }
  // })

  // it("11", async function () {
  //   await bridge.relay_eth_header()
  //   await sleep(3000)
  // })

  // it("12", async function () {
  //   await sleep(3000)
  //   const i = await ethClient.inbound.data()
  //   const o = await subClient.outbound.outboundLaneNonce()
  //   const tx = await bridge.confirm_sub_messages()
  //   await expect(tx)
  //     .to.emit(subClient.outbound, "MessagesDelivered")
  //     .withArgs(o.latest_received_nonce.add(1), i.last_delivered_nonce, 0)
  // })
})
