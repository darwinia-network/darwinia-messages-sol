const { expect } = require("chai")
const { BigNumber } = require("ethers");
const { solidity } = require("ethereum-waffle")
const { bootstrap } = require("./fixture")
const chai = require("chai")

chai.use(solidity)
const log = console.log
const LANE_IDENTIFY_SLOT="0x0000000000000000000000000000000000000000000000000000000000000000"
const LANE_NONCE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000001"
const LANE_MESSAGE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000002"
let ethClient, subClient
let overrides = { value: ethers.utils.parseEther("30") }

const get_storage_proof = async (storageKeys, blockNumber = 'latest') => {
  return await ethClient.provider.send("eth_getProof",
    [
      ethClient.outbound.address,
      storageKeys,
      ethers.utils.hexlify(blockNumber)
    ]
  )
}

const generate_storage_proof = async (nonce) => {
  const laneIdProof = await get_storage_proof([LANE_IDENTIFY_SLOT])
  const laneNonceProof = await get_storage_proof([LANE_NONCE_SLOT])
  const newKeyPreimage = ethers.utils.concat([
      utils.hexZeroPad(nonce, 32),
      LANE_MESSAGE_SLOT,
  ])
  console.log("New Key Preimage:", ethers.utils.hexlify(newKeyPreimage))
  const key = ethers.utils.keccak256(newKeyPreimage)
  console.log("New Key:", key)
  const laneMessageProof = await get_storage_proof([key])
  const proof = {
    "accountProof": laneIdProof.accountProof,
    "laneIDProof": laneIdProof.storageProof,
    "laneNonceProof": laneNonceProof.storageProof,
    "laneMessagesProof": laneMessageProof.storageProof,
  }
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(bytes[] accountProof, bytes[] laneIDProof, bytes[] laneNonceProof, bytes[][] laneMessagesProof)"
    ], [ proof ])
}

const get_message_proof = async () => {
  const thisChainPos = subClient.inbound.thisChainPosition()
  const bridgedChainPos = subClient.inbound.bridgedChainPosition()
  const c0 = await subClient.chainMessageCommitter['commitment(uint256)'](thisChainPos)
  const c1 = await subClient.chainMessageCommitter['commitment(uint256)'](bridgedChainPos)
  const c = await subClient.chainMessageCommitter['commitment()']
  const thisInLanePos = await subClient.inbound.thisLanePosition()
  const inb = await subClient.laneMessageCommitter['commitment(uint256)'](thisInLanePos)
  const chainProof = {
    root: c,
    count: 2,
    proof: [c0]
  }
  const laneProof = {
    root: c1,
    count: 2,
    proof: [inb]
  }
  return {chainProof, laneProof}
}

const generate_message_proof = async () => {
  const proof = await get_message_proof()
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(tuple(bytes32 root, uint256 count, bytes32[] proof) chainProof, tuple(bytes32 root, uint256 count, bytes32[] root) laneProof)"
  ],[
    [
      proof
    ]
  ])
}

describe("bridge e2e test: verify message storage proof", () => {

  before(async () => {
    const clients = await bootstrap()
    ethClient = clients.ethClient
    subClient = clients.subClient
  })

  it("0", async function () {
    const tx = await ethClient.outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x",
      overrides
    )
    await expect(tx)
      .to.emit(ethClient.outbound, "MessageAccepted")
      .withArgs(1, "0x")
  })

  it("1", async function () {
    // await subClient.lightClient.relayHeader(c)
  })

  it("2", async function () {
    const o = await ethClient.outbound.data()
    const calldata = Array(o.messages.length).fill("0x")
    const proof = await generate_storage_proof()
    const tx = await subClient.inbound.receive_messages_proof(o, calldata, proof)
    await expect(tx)
      .to.emit(subClient.inbound, "MessageDispatched")
      .withArgs(
        ethClient.outbound.thisChainPosition(),
        ethClient.outbound.thisLanePosition(),
        ethClient.outbound.bridgedChainPosition(),
        ethClient.outbound.bridgedLanePosition(),
        1,
        false,
        "0x4c616e653a204d65737361676543616c6c52656a6563746564"
      )
  })

  it("3", async function () {
    // await subClient.lightClient.relayHeader(c)
  })

  it("4", async function () {
    await receive_messages_delivery_proof(sourceOutbound, targetOutbound, targetInbound, 1, 1)
    const i = await subClient.inbound.data()
    const proof = await generate_message_proof()
    const tx = ethClient.outbound.receive_messages_delivery_proof(i, proof)
    await expect(tx)
      .to.emit(ethClient.outbound, "MessagesDelivered")
      .withArgs(1, 1, 0)
  })

})
