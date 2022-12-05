const { expect } = require("chai")
const { waffle } = require("hardhat");
const { BigNumber } = require("ethers");
const { bootstrap } = require("./helper/fixture")
const chai = require("chai")
const { solidity } = waffle;

chai.use(solidity)
const log = console.log
const LANE_ROOT_SLOT="0x0000000000000000000000000000000000000000000000000000000000000001"
let ethClient, subClient, bridge
let eth_signer, source
const target = "0x0000000000000000000000000000000000000000"
const encoded = "0x"

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
    subClient = clients.subClient
    bridge = clients.bridge

    eth_signer = ethClient.get_signer(0)
    source = eth_signer.address
  })

  it.skip("1", async () => {
    const nonce = await ethClient.parallel_outbound.message_size()
    const tx = await ethClient.parallel_outbound.send_message(
      target,
      encoded
    )
    await expect(tx)
      .to.emit(ethClient.parallel_outbound, "MessageAccepted")
      .withArgs(
        nonce,
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

  it.skip("2", async function () {
    const nonce = await ethClient.parallel_outbound.message_size()
    const encoded_key = await ethClient.parallel_outbound.encodeMessageKey(nonce)
    const message = {
      encoded_key,
      payload: {
        source,
        target,
        encoded
      }
    }

    const tx = await bridge.confirm_messages_to_sub('eth')
    await expect(tx)
      .to.emit(ethClient.outbound, "MessagesDelivered")
      .withArgs(o.latest_received_nonce.add(1), i.last_delivered_nonce)
  })

  it.skip("4.2", async function () {
    const i = await subClient.bsc.inbound.data()
    const o = await bscClient.outbound.outboundLaneNonce()
    const tx = await bridge.confirm_messages_to_sub('bsc')
    await expect(tx)
      .to.emit(ethClient.outbound, "MessagesDelivered")
      .withArgs(o.latest_received_nonce.add(1), i.last_delivered_nonce, 0)
  })

  it.skip("5.1", async function () {
    const nonce = await subClient.eth.outbound.outboundLaneNonce()
    const tx = await subClient.eth.outbound.send_message(
      target,
      encoded,
      sub_overrides
    )

    await expect(tx)
      .to.emit(subClient.eth.outbound, "MessageAccepted")
      .withArgs(
        nonce.latest_generated_nonce.add(1),
        source,
        target,
        encoded
      )
  })

  it.skip("5.2", async function () {
    const nonce = await subClient.bsc.outbound.outboundLaneNonce()
    const tx = await subClient.bsc.outbound.send_message(
      target,
      encoded,
      eth_overrides
    )

    await expect(tx)
      .to.emit(subClient.bsc.outbound, "MessageAccepted")
      .withArgs(
        nonce.latest_generated_nonce.add(1),
        source,
        target,
        encoded
      )
  })

  it.skip("6", async function () {
    await bridge.relay_sub_header()
  })

  it.skip("7.1", async function () {
    const o = await subClient.eth.outbound.data()
    const begin = (await subClient.eth.inbound.inboundLaneNonce()).last_delivered_nonce.add(1)
    let data = build_land_data(o)
    const tx = await bridge.dispatch_messages_from_sub('eth', data)
    const end = (await subClient.eth.inbound.inboundLaneNonce()).last_delivered_nonce
    for (let i=begin; i<=end; i++) {
      await expect(tx)
        .to.emit(ethClient.inbound, "MessageDispatched")
        .withArgs(
          i,
          false
        )
    }
  })

  it.skip("7.2", async function () {
    const o = await subClient.bsc.outbound.data()
    const begin = (await subClient.bsc.inbound.inboundLaneNonce()).last_delivered_nonce.add(1)
    let data = build_land_data(o)
    const tx = await bridge.dispatch_messages_from_sub('bsc', data)
    const end = (await subClient.bsc.inbound.inboundLaneNonce()).last_delivered_nonce
    for (let i=begin; i<=end; i++) {
      await expect(tx)
        .to.emit(bscClient.inbound, "MessageDispatched")
        .withArgs(
          i,
          false
        )
    }
  })

  it.skip("8.1", async function () {
    await bridge.relay_eth_header()
  })

  it.skip("8.2", async function () {
    await bridge.relay_eth_execution_payload()
  })

  it.skip("9", async function () {
    const i = await ethClient.inbound.data()
    const o = await subClient.eth.outbound.outboundLaneNonce()
    const tx = await bridge.confirm_messages_from_sub('eth')
    await expect(tx)
      .to.emit(subClient.eth.outbound, "MessagesDelivered")
      .withArgs(o.latest_received_nonce.add(1), i.last_delivered_nonce)
  })
})
