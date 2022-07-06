const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");
const { Fixure } = require("./shared/fixture")

chai.use(solidity);
const log = console.log
const thisChainPos = 0
const thisLanePos = 0
const bridgedChainPos = 1
const bridgedLanePos = 1
let source, addr1, addr2
let feeMarket, outbound, inbound
let outboundData, inboundData
let overrides = { value: ethers.utils.parseEther("30") }
const target = "0x0000000000000000000000000000000000000000"
const encoded = "0x"
const encoded_hash = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"

const send_message = async (nonce) => {
    const tx = await outbound.send_message(
      target,
      encoded,
      overrides
    )
    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(nonce, source, target, encoded)
    await logNonce()
}

const logNonce = async () => {
  const out = await outbound.outboundLaneNonce()
  const iin = await inbound.inboundLaneNonce()
  log(`(${out.latest_received_nonce}, ${out.latest_generated_nonce}]                                            ->     (${iin.last_confirmed_nonce}, ${iin.last_delivered_nonce}]`)
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

const receive_messages_proof = async (nonce) => {
    const laneData = await outbound.data()
    let data = build_land_data(laneData)
    const from = (await inbound.inboundLaneNonce()).last_delivered_nonce.toNumber()
    const size = nonce - from
    const tx = await inbound.connect(addr2).receive_messages_proof(data, "0x")
    for (let i = 0; i<size; i++) {
      await expect(tx)
        .to.emit(inbound, "MessageDispatched")
        .withArgs(from+i+1, false)
    }
    await logNonce()
}

const receive_messages_delivery_proof = async (begin, end) => {
    const laneData = await inbound.data()
    const tx = await outbound.connect(addr1).receive_messages_delivery_proof(laneData, "0x")
    await expect(tx)
      .to.emit(outbound, "MessagesDelivered")
      .withArgs(begin, end, 0)
    await logNonce()
}

//   out bound lane                                    ->           in bound lane
//   (latest_received_nonce, latest_generated_nonce]   ->     (last_confirmed_nonce, last_delivered_nonce]
//0  (0, 1]   #send_message                            ->     (0, 0]
//1  (0, 1]                                            ->     (0, 1]  #receive_messages_proof
//2  (1, 1]   #receive_messages_delivery_proof         ->     (0, 1]
//3  (1, 1]                                            ->     (1, 1]  #receive_messages_proof
describe("reward message relay tests", () => {

  before(async () => {
    ({ feeMarket, outbound, inbound } = await waffle.loadFixture(Fixure));
    [owner, addr1, addr2] = await ethers.getSigners();
    source = owner.address

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
    await receive_messages_delivery_proof(1, 1)
  })

  it("3", async function () {
    await receive_messages_proof(1)
  })

  it("4", async function () {
    const tx = await outbound.send_message(
      target,
      encoded,
      overrides
    )
    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(2, source, target, encoded)
    await expect(tx)
      .to.emit(outbound, "MessagePruned")
      .withArgs(2)
    await logNonce()
  })
})
