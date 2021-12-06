const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");

chai.use(solidity);
const log = console.log
const thisChainPos = 0
const thisLanePos = 0
const bridgedChainPos = 1
const bridgedLanePos = 1
let outbound, inbound
let outboundData, inboundData, a, b, c, d
let overrides = { value: ethers.utils.parseEther("30") }

const send_message = async (nonce) => {
    const tx = await outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x",
      overrides
    )
    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(nonce)
    await logNonce()
}

const logNonce = async () => {
  const out = await outbound.outboundLaneNonce()
  const iin = await inbound.inboundLaneNonce()
  log(`(${out.latest_received_nonce}, ${out.latest_generated_nonce}]                                            ->     (${iin.last_confirmed_nonce}, ${iin.last_delivered_nonce}]`)
}

const receive_messages_proof = async (laneData, nonce) => {
    const tx = await inbound.receive_messages_proof(laneData, "0x")
    const n = await inbound.inboundLaneNonce()
    const size = n.last_delivered_nonce - nonce
    for (let i = 0; i<size; i++) {
      await expect(tx)
        .to.emit(inbound, "MessageDispatched")
        .withArgs(thisChainPos, thisLanePos, bridgedChainPos, bridgedLanePos, nonce+i, false, "0x4c616e653a204d65737361676543616c6c52656a6563746564")
    }
    await logNonce()
}

const receive_messages_delivery_proof = async (laneData, begin, end) => {
    const tx = await outbound.receive_messages_delivery_proof(laneData, "0x")
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
//3  (1, 1]                                            ->     (1, 1]  #receive_messages_proof                       // here, new_confirmed_nonce = last_delivered_nonce
//   -----------------------------------------------------------------------------------------------------
//4  (1, 2]   #send_message                            ->     (1, 1]
//5  (1, 2]                                            ->     (1, 2]  #receive_messages_proof.a
//6  (1, 3]   #send_message                            ->     (1, 2]
//7  (1, 3]                                            ->     (1, 3]  #receive_messages_proof.b
//8  (1, 4]   #send_message                            ->     (1, 3]
//9  (2, 4]   #receive_messages_delivery_proof.a       ->     (1, 3]
//10 (2, 4]                                            ->     (2, 3]  #receive_messages_proof.receive_state_update  // here, new_confirmed_nonce < last_delivered_nonce
//                                                     ->     (2, 4]  #receive_messages_proof.receive_message.c
//11 (3, 4]   #receive_messages_delivery_proof.b       ->     (2, 4]
//12 (3, 4]                                            ->     (3, 4]  #receive_messages_proof.receive_state_update  // here, new_confirmed_nonce < last_delivered_nonce
//                                                     ->     (3, 4]  #receive_messages_proof.receive_message.d
//13 (4, 4]   #receive_messages_delivery_proof.c|d     ->     (3, 4]
//14 (4, 4]                                            ->     (4, 4]  #receive_messages_proof
describe("async message relay tests", () => {

  before(async () => {
    const [owner] = await ethers.getSigners();
    const MockLightClient = await ethers.getContractFactory("MockLightClient")
    const lightClient = await MockLightClient.deploy()
    const OutboundLane = await ethers.getContractFactory("OutboundLane")
    outbound = await OutboundLane.deploy(lightClient.address, thisChainPos, thisLanePos, bridgedChainPos, bridgedLanePos, 1, 0, 0)
    await outbound.grantRole("0x7bb193391dc6610af03bd9922e44c83b9fda893aeed61cf64297fb4473500dd1", owner.address)
    const InboundLane = await ethers.getContractFactory("InboundLane")
    inbound = await InboundLane.deploy(lightClient.address, bridgedChainPos, bridgedLanePos, thisChainPos, thisLanePos, 0, 0)
    log(" out bound lane                                   ->      in bound lane")
    log("(latest_received_nonce, latest_generated_nonce]   ->     (last_confirmed_nonce, last_delivered_nonce]")
  });

  it("0", async function () {
    await send_message(1)
  });

  it("1", async function () {
    outboundData = await outbound.data()
    await receive_messages_proof(outboundData, 1)
  });

  it("2", async function () {
    inboundData = await inbound.data()
    await receive_messages_delivery_proof(inboundData, 1, 1)
  });

  it("3", async function () {
    outboundData = await outbound.data()
    await receive_messages_proof(outboundData, 1)
  });

  it("4", async function () {
    await send_message(2)
  });

  it("5", async function () {
    outboundData = await outbound.data()
    await receive_messages_proof(outboundData, 2)
    a = await inbound.data()
  });

  it("6", async function () {
    await send_message(3)
  });

  it("7", async function () {
    outboundData = await outbound.data()
    await receive_messages_proof(outboundData, 3)
    b = await inbound.data()
  });

  it("8", async function () {
    await send_message(4)
  });

  it("9", async function () {
    await receive_messages_delivery_proof(a, 2, 2)
  });

  it("10", async function () {
    outboundData = await outbound.data()
    await receive_messages_proof(outboundData, 4)
    c = await inbound.data()
  });

  it("11", async function () {
    await receive_messages_delivery_proof(b, 3, 3)
  });

  it("12", async function () {
    outboundData = await outbound.data()
    await receive_messages_proof(outboundData, 4)
    d = await inbound.data()
  });

  it("13", async function () {
    await receive_messages_delivery_proof(c, 4, 4)
    // await receive_messages_delivery_proof(d, 4, 4)
  });

  it("14", async function () {
    outboundData = await outbound.data()
    await receive_messages_proof(outboundData, 4)
  });
});
