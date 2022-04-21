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
let fee = ethers.utils.parseEther("30")
let overrides = { value: fee }

const batch = 1
const encoded = "0x"
const send_message = async (nonce) => {
    let to = normalApp.address
    const tx = await outbound.send_message(
      to,
      encoded,
      overrides
    )
    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(nonce, owner.address, to, encoded)
    await logNonce()
}

const logNonce = async () => {
  const out = await outbound.outboundLaneNonce()
  const iin = await inbound.inboundLaneNonce()
  log(`(${out.latest_received_nonce}, ${out.latest_generated_nonce}]                                            ->     (${iin.last_confirmed_nonce}, ${iin.last_delivered_nonce}]`)
}

const receive_messages_proof = async (nonce) => {
    const payload = {
      source: owner.address,
      target: normalApp.address,
      encoded: encoded
    }
    let laneData = await outbound.data()
    let data = {
      latest_received_nonce: laneData.latest_received_nonce,
      messages: []
    }
    for (let i = 0; i< laneData.messages.length; i++) {
      let message = {
        encoded_key: laneData.messages[i].encoded_key,
        payload: payload
      }
      data.messages.push(message)
    }
    const from = (await inbound.inboundLaneNonce()).last_delivered_nonce.toNumber()
    const size = nonce - from
    let relayer = ethers.Wallet.createRandom();
    await owner.sendTransaction({
        to: relayer.address,
        value: ethers.utils.parseEther("1.0")
    })
    relayer = relayer.connect(ethers.provider)
    const tx = await inbound.connect(relayer).receive_messages_proof(data, "0x", {
      gasLimit: 10000000
    })
    for (let i = 0; i<size; i++) {
      await expect(tx)
        .to.emit(inbound, "MessageDispatched")
        .withArgs(from+i+1, true)
    }
    await logNonce()
}

const receive_messages_delivery_proof = async (begin, end) => {
    let laneData = await inbound.data()
    const payload = {
      source: owner.address,
      target: normalApp.address,
      encoded_hash: "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
    }
    const tx = await outbound.connect(addr1).receive_messages_delivery_proof(laneData, [payload], "0x")
    await expect(tx)
      .to.emit(outbound, "MessagesDelivered")
      .withArgs(begin, end, 1)
    await logNonce()
}

//   out bound lane                                    ->           in bound lane
//   (latest_received_nonce, latest_generated_nonce]   ->     (last_confirmed_nonce, last_delivered_nonce]
//0  (0,  1]   #send_message                            ->     (0, 0]
//1  (0,  1]                                            ->     (0, 1]  #receive_messages_proof
//2  (1 , 1]   #receive_messages_delivery_proof         ->     (0, 1]
describe("normal app send single message tests", () => {

  before(async () => {
    ({ outbound, inbound } = await waffle.loadFixture(Fixure));
    [owner, addr1, addr2] = await ethers.getSigners();

    const SimpleFeeMarket = await ethers.getContractFactory("SimpleFeeMarket")
    feeMarket = await SimpleFeeMarket.deploy(ethers.utils.parseEther("10"), 100, 100)

    let overrides = { value: ethers.utils.parseEther("3000") }
    await feeMarket.connect(owner).enroll("0x0000000000000000000000000000000000000001", fee, overrides)
    await outbound.setFeeMarket(feeMarket.address)
    await feeMarket.setOutbound(outbound.address, 1)

    const NormalApp = await ethers.getContractFactory("NormalApp")
    normalApp = await NormalApp.deploy("0x0000000000000000000000000000000000000000")
    outbound.rely(normalApp.address)
    log(" out bound lane                                   ->      in bound lane")
    log("(latest_received_nonce, latest_generated_nonce]   ->     (last_confirmed_nonce, last_delivered_nonce]")
  })

  it("0", async function () {
    for(let i=1; i <=batch; i++) {
      await send_message(i)
    }
  })

  it("1", async function () {
    await receive_messages_proof(batch)
  })

  it("2", async function () {
    await receive_messages_delivery_proof(1, batch)
  })
})
