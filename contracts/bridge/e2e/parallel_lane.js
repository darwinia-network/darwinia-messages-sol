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
const sub_target = "0x4DBdC9767F03dd078B5a1FC05053Dd0C071Cc005"
const eth_target = "0xbB8Ac813748e57B6e8D2DfA7cB79b641bD0524c1"
const encoded = "0x"

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
      sub_target,
      encoded
    )
    await expect(tx)
      .to.emit(ethClient.parallel_outbound, "MessageAccepted")
      .withArgs(
        nonce,
        source,
        sub_target,
        encoded
      )

    const encoded_key = await ethClient.parallel_outbound.encodeMessageKey(nonce)
    const message = {
      encoded_key,
      payload: {
        source,
        target: sub_target,
        encoded
      }
    }
    log(message)
  })

  it.skip("1.1", async function () {
    await bridge.relay_eth_header()
  })

  it.skip("1.2", async function () {
    await bridge.relay_eth_execution_payload()
  })

  it.skip("2", async function () {
    const nonce = (await ethClient.parallel_outbound.message_size()).sub(1)
    const encoded_key = await ethClient.parallel_outbound.encodeMessageKey(nonce)
    const message = {
      encoded_key,
      payload: {
        source,
        target: sub_target,
        encoded
      }
    }

    const tx = await bridge.dispatch_parallel_message_to_sub('eth', message)
    log(tx)
    await expect(tx)
      .to.emit(subClient.parallel_inbound, "MessagesDelivered")
      .withArgs(nonce)
  })

  it.skip("3", async function () {
    const nonce = await subClient.eth.parallel_outbound.message_size()
    const tx = await subClient.eth.parallel_outbound.send_message(
      eth_target,
      encoded
    )

    await expect(tx)
      .to.emit(subClient.eth.parallel_outbound, "MessageAccepted")
      .withArgs(
        nonce,
        source,
        eth_target,
        encoded
      )

    const encoded_key = await subClient.eth.parallel_outbound.encodeMessageKey(nonce)
    const message = {
      encoded_key,
      payload: {
        source,
        target: eth_target,
        encoded
      }
    }
    log(message)
  })

  it.skip("3.1", async function () {
    await bridge.relay_sub_header()
  })

  it("3.2", async function () {
    const nonce = (await subClient.eth.parallel_outbound.message_size()).sub(1)
    const encoded_key = await subClient.eth.parallel_outbound.encodeMessageKey(nonce)
    const message = {
      encoded_key,
      payload: {
        source,
        target: eth_target,
        encoded
      }
    }
    log(message)

    const tx = await bridge.dispatch_parallel_message_from_sub('eth', message)
    log(tx)
    await expect(tx)
      .to.emit(subClient.eth.parallel_inbound, "MessagesDelivered")
      .withArgs(nonce)
  })
})
