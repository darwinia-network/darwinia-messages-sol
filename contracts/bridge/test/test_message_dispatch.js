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
let feeMarket, outbound, inbound, normalApp
let outboundData, inboundData
let overrides = { value: ethers.utils.parseEther("30") }
const target = "0x0000000000000000000000000000000000000000"
const encoded = "0x"
const encoded_hash = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"

const send_message = async (nonce) => {
    let to = nonce%2 == 0 ? normalApp.address : target
    const tx = await outbound.send_message(
      to,
      encoded,
      overrides
    )
    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(nonce, source, to, encoded)
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
      let to = laneData.messages[i].encoded_key.mod(2) == 0 ? normalApp.address : target
      let message = {
        encoded_key: laneData.messages[i].encoded_key,
        payload: {
          source,
          target: to,
          encoded,
        }
      }
      data.messages.push(message)
    }
    return data
}

const receive_messages_proof = async (addr, nonce) => {
    laneData = await outbound.data()
    let data = build_land_data(laneData)
    const from = (await inbound.inboundLaneNonce()).last_delivered_nonce.toNumber()
    const size = nonce - from
    const tx = await inbound.connect(addr).receive_messages_proof(data, "0x")
    for (let i = 0; i<size; i++) {
      let n = from+i+1
      let result = n%2 == 0 ? true : false
      await expect(tx)
        .to.emit(inbound, "MessageDispatched")
        .withArgs(n, result)
    }
    await logNonce()
}

const receive_messages_delivery_proof = async (addr, begin, end) => {
    let payloads = []
    for(let i=begin; i<=end; i++){
      let payload = {
        source,
        target: i%2 == 0 ? normalApp.address : target,
        encoded_hash
      }
      payloads.push(payload)
    }
    laneData = await inbound.data()
    const tx = await outbound.connect(addr).receive_messages_delivery_proof(laneData, payloads, "0x")
    const d = await tx.wait();
    await expect(tx)
      .to.emit(outbound, "MessagesDelivered")
      .withArgs(begin, end, "0x2a")
}

describe("multi message relay tests", () => {

  before(async () => {
    ({ feeMarket, outbound, inbound } = await waffle.loadFixture(Fixure));
    [source, addr1, addr2] = await ethers.getSigners();
    source = source.address

    const NormalApp = await ethers.getContractFactory("NormalApp")
    normalApp = await NormalApp.deploy("0x0000000000000000000000000000000000000000")

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
