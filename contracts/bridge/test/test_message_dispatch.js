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
let owner, addr1, addr2
let feeMarket, outbound, inbound, normalApp
let outboundData, inboundData
let overrides = { value: ethers.utils.parseEther("30") }

const send_message = async (nonce) => {
    let to = "0x0000000000000000000000000000000000000000"
    if (nonce%2 == 0) {
      to = normalApp.address
    }
    const tx = await outbound.send_message(
      to,
      "0x",
      overrides
    )
    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(nonce, "0x")
    await logNonce()
}

const logNonce = async () => {
  const out = await outbound.outboundLaneNonce()
  const iin = await inbound.inboundLaneNonce()
  log(`(${out.latest_received_nonce}, ${out.latest_generated_nonce}]                                            ->     (${iin.last_confirmed_nonce}, ${iin.last_delivered_nonce}]`)
}

const receive_messages_proof = async (addr, nonce) => {
    laneData = await outbound.data()
    const calldata = Array(laneData.messages.length).fill("0x")
    const from = (await inbound.inboundLaneNonce()).last_delivered_nonce.toNumber()
    const size = nonce - from
    const tx = await inbound.connect(addr).receive_messages_proof(laneData, calldata, "0x")
    for (let i = 0; i<size; i++) {
      let result = false
      let returndata = "0x4c616e653a204d65737361676543616c6c52656a6563746564"
      let n = from+i+1
      if (n%2 == 0) {
        result = true
        returndata = "0x"
      }
      await expect(tx)
        .to.emit(inbound, "MessageDispatched")
        .withArgs(thisChainPos, thisLanePos, bridgedChainPos, bridgedLanePos, n, result, returndata)
    }
    await logNonce()
}

const receive_messages_delivery_proof = async (addr, begin, end) => {
    laneData = await inbound.data()
    const tx = await outbound.connect(addr).receive_messages_delivery_proof(laneData, "0x")
    const d = await tx.wait();
    await expect(tx)
      .to.emit(outbound, "MessagesDelivered")
      .withArgs(begin, end, "0x2a")
}

describe("multi message relay tests", () => {

  before(async () => {
    ({ feeMarket, outbound, inbound } = await waffle.loadFixture(Fixure));
    [owner, addr1, addr2] = await ethers.getSigners();

    const NormalApp = await ethers.getContractFactory("NormalApp")
    normalApp = await NormalApp.deploy("0x0000000000000000000000000000000000000000")
    outbound.rely(normalApp.address)

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
