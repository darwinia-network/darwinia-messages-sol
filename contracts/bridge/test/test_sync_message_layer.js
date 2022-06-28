const { expect } = require("chai")
const { solidity } = require("ethereum-waffle")
const chai = require("chai")
const { Fixure } = require("./shared/fixture")

chai.use(solidity)
const log = console.log
const thisChainPos = 0
const thisLanePos = 0
const bridgedChainPos = 1
const bridgedLanePos = 1
let feeMarket, outbound, inbound
let outboundData, inboundData
let overrides = { value: ethers.utils.parseEther("30") }
let source
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
    let block = await ethers.provider.getBlock(tx.blockNumber)
    await expect(tx)
      .to.emit(feeMarket, "Assgigned")
      .withArgs(await outbound.encodeMessageKey(nonce), block.timestamp, await feeMarket.assignedRelayersNumber(), await feeMarket.collateralPerOrder())

    const [one, two, three] = await ethers.getSigners();
    await expect(tx)
      .to.emit(feeMarket, "Locked")
      .withArgs(three.address, await feeMarket.collateralPerOrder())
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
    const data = build_land_data(laneData)
    const from = (await inbound.inboundLaneNonce()).last_delivered_nonce.toNumber()
    const size = nonce - from
    const tx = await inbound.receive_messages_proof(data, "0x")
    for (let i = 0; i<size; i++) {
      await expect(tx)
        .to.emit(inbound, "MessageDispatched")
        .withArgs(from+i+1, false)
    }
    await logNonce()
}

const receive_messages_delivery_proof = async (begin, end) => {
    const [one, two, three, four] = await ethers.getSigners();
    const laneData = await inbound.data()
    const tx = await outbound.connect(four).receive_messages_delivery_proof(laneData, "0x")
    await expect(tx)
      .to.emit(outbound, "MessagesDelivered")
      .withArgs(begin, end, 0)
    for (let i = begin; i<=end; i++) {

      let block = await ethers.provider.getBlock(tx.blockNumber)
      await expect(tx)
        .to.emit(feeMarket, "Settled")
        .withArgs(await outbound.encodeMessageKey(i), block.timestamp)
    }
    let n = end - begin + 1;
    let messageFee = ethers.utils.parseEther("30").mul(n)
    let baseFee = ethers.utils.parseEther("10").mul(n)
    let assign_reward = baseFee.mul(60).div(100)
    let other_reward = baseFee.sub(assign_reward)
    let delivery_reward = other_reward.mul(80).div(100)
    let confirm_reward = other_reward.sub(delivery_reward)
    await expect(tx)
      .to.emit(feeMarket, "Reward")
      .withArgs(one.address, delivery_reward.add(assign_reward))
    await expect(tx)
      .to.emit(feeMarket, "Reward")
      .withArgs(four.address, confirm_reward)
    await expect(tx)
      .to.emit(feeMarket, "Reward")
      .withArgs("0x0000000000000000000000000000000000000000", messageFee.sub(baseFee))
    await logNonce()
}

//   out bound lane                                    ->           in bound lane
//   (latest_received_nonce, latest_generated_nonce]   ->     (last_confirmed_nonce, last_delivered_nonce]
//0  (0, 1]   #send_message                            ->     (0, 0]
//1  (0, 1]                                            ->     (0, 1]  #receive_messages_proof
//2  (1, 1]   #receive_messages_delivery_proof         ->     (0, 1]
//3  (1, 1]                                            ->     (1, 1]  #receive_messages_proof
//   -----------------------------------------------------------------------------------------------------
//4  (1, 2]   #send_message                            ->     (1, 1]
//5  (1, 2]                                            ->     (1, 2]  #receive_messages_proof
//6  (1, 3]   #send_message                            ->     (1, 2]
//7  (1, 3]                                            ->     (1, 3]  #receive_messages_proof
//8  (1, 4]   #send_message                            ->     (1, 3]
//9  (3, 4]   #receive_messages_delivery_proof         ->     (1, 3]
//10 (3, 4]                                            ->     (3, 3]  #receive_messages_proof.receive_state_update
//                                                     ->     (3, 4]  #receive_messages_proof.receive_message.c
//11 (4, 4]   #receive_messages_delivery_proof         ->     (2, 4]
//12 (4, 4]                                            ->     (4, 4]  #receive_messages_proof
describe("sync message relay tests", () => {

  before(async () => {
    ({ feeMarket, outbound, inbound } = await waffle.loadFixture(Fixure));
    [source] = await ethers.getSigners();
    source = source.address;
    log(" out bound lane                                   ->      in bound lane")
    log("(latest_received_nonce, latest_generated_nonce]   ->     (last_confirmed_nonce, last_delivered_nonce]")
  });

  it("enrol a relayer", async () => {
    const [one, two, three, four] = await ethers.getSigners();
    let overrides = { value: ethers.utils.parseEther("100") }
    let tx = await feeMarket.connect(four).enroll(three.address, ethers.utils.parseEther("40"), overrides)
    expect(tx)
      .to.emit(feeMarket, "Enrol")
      .withArgs(three.address, four.address, ethers.utils.parseEther("40"))
    expect(tx)
      .to.emit(feeMarket, "Deposit")
      .withArgs(four.address, ethers.utils.parseEther("100"))
  })

  it("delist a relayer", async () => {
    const [one, two, three, four] = await ethers.getSigners();
    let tx = await feeMarket.connect(four).leave(three.address)
    expect(tx)
      .to.emit(feeMarket, "Delist")
      .withArgs(three.address, four.address)
    expect(tx)
      .to.emit(feeMarket, "Withdrawal")
      .withArgs(four.address, ethers.utils.parseEther("100"))
  })

  it("encodeMessageKey", async () => {
    let messageKey = await outbound.encodeMessageKey(1)
    expect(messageKey).to.eq("0x0000000000000000000000000000000000000001000000010000000000000001")
  })

  it("0", async function () {
    await send_message(1)
  });

  it("1", async function () {
    await receive_messages_proof(1)
  });

  it("2", async function () {
    await receive_messages_delivery_proof(1, 1)
  });

  it("3", async function () {
    await receive_messages_proof(1)
  });

  it("4", async function () {
    await send_message(2)
  });

  it("5", async function () {
    await receive_messages_proof(2)
  });

  it("6", async function () {
    await send_message(3)
  });

  it("7", async function () {
    await receive_messages_proof(3)
  });

  it("8", async function () {
    await send_message(4)
  });

  it("9", async function () {
    await receive_messages_delivery_proof(2, 3)
  });

  it("10", async function () {
    await receive_messages_proof(4)
  });

  it("11", async function () {
    await receive_messages_delivery_proof(4, 4)
  });

  it("12", async function () {
    await receive_messages_proof(4)
  });
});
