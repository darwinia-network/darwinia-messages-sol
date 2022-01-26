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
const overrides = { value: ethers.utils.parseEther("30") }
let ethClient, subClient

const get_storage_proof = async (storageKeys, blockNumber = 'latest') => {
  return await ethClient.provider.send("eth_getProof",
    [
      ethClient.outbound.address,
      storageKeys,
      blockNumber
    ]
  )
}

const generate_storage_proof = async (nonce) => {
  const laneIdProof = await get_storage_proof([LANE_IDENTIFY_SLOT])
  const laneNonceProof = await get_storage_proof([LANE_NONCE_SLOT])
  const newKeyPreimage = ethers.utils.concat([
      ethers.utils.hexZeroPad(nonce, 32),
      LANE_MESSAGE_SLOT,
  ])
  const key0 = ethers.utils.keccak256(newKeyPreimage)
  const key1 = BigNumber.from(key0).add(1).toHexString()
  const key2 = BigNumber.from(key0).add(2).toHexString()
  const laneMessageProof = await get_storage_proof([key0, key1, key2])
  const proof = {
    "accountProof": laneIdProof.accountProof,
    "laneIDProof": laneIdProof.storageProof[0].proof,
    "laneNonceProof": laneNonceProof.storageProof[0].proof,
    "laneMessagesProof": laneMessageProof.storageProof.map((p) => p.proof),
  }
  log(JSON.stringify(laneMessageProof, null, 2))
  // log(JSON.stringify(proof, null, 2))
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(bytes[] accountProof, bytes[] laneIDProof, bytes[] laneNonceProof, bytes[][] laneMessagesProof)"
    ], [ proof ])
}

const get_message_proof = async () => {
  const thisChainPos = await subClient.inbound.thisChainPosition()
  const bridgedChainPos = await subClient.inbound.bridgedChainPosition()
  const c0 = await subClient.chainMessageCommitter['commitment(uint256)'](thisChainPos)
  const c1 = await subClient.chainMessageCommitter['commitment(uint256)'](bridgedChainPos)
  const c = await subClient.chainMessageCommitter['commitment()']()
  const thisOutLanePos = await subClient.outbound.thisLanePosition()
  const outb = await subClient.laneMessageCommitter['commitment(uint256)'](thisOutLanePos)
  const chainProof = {
    root: c,
    count: 2,
    proof: [c0]
  }
  const laneProof = {
    root: c1,
    count: 2,
    proof: [outb]
  }
  return {chainProof, laneProof}
}

const generate_message_proof = async () => {
  const proof = await get_message_proof()
  log(proof)
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(tuple(bytes32,uint256,bytes32[]),tuple(bytes32,uint256,bytes32[]))"
    ], [
      [
        [proof.chainProof.root, proof.chainProof.count, proof.chainProof.proof],
        [proof.laneProof.root, proof.laneProof.count, proof.laneProof.proof]
      ]
    ])
}

describe("bridge e2e test: verify message storage proof", () => {

  before(async () => {
  })

  it("bootstrap", async () => {
    const clients = await bootstrap()
    ethClient = clients.ethClient
    subClient = clients.subClient
    await ethClient.enroll_relayer()
    await subClient.enroll_relayer()
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
    const header = await ethClient.block_header()
    await subClient.relay_header(header.stateRoot)
  })

  it("2", async function () {
    const overrides = { gasLimit: 6000000 }
    const o = await ethClient.outbound.data()
    const calldata = Array(o.messages.length).fill("0x")
    const proof = await generate_storage_proof(1)
    log(JSON.stringify(o, null, 1))
    log(await ethClient.outbound.commitment())
    // log(proof)
    const tx = await subClient.inbound.receive_messages_proof(o, calldata, proof, overrides)
    log(await tx.wait())
    await expect(tx)
      .to.emit(subClient.inbound, "MessageDispatched")
      .withArgs(
        await ethClient.outbound.thisChainPosition(),
        await ethClient.outbound.thisLanePosition(),
        await ethClient.outbound.bridgedChainPosition(),
        await ethClient.outbound.bridgedLanePosition(),
        1,
        false,
        "0x4c616e653a204d65737361676543616c6c52656a6563746564"
      )
  })

  it("3", async function () {
    const header = await subClient.block_header()
    const message_root = await subClient.chainMessageCommitter['commitment()']()
    await ethClient.relay_header(message_root, header.number.toString())
  })

  it("4", async function () {
    const overrides = { gasLimit: 6000000 }
    const i = await subClient.inbound.data()
    const proof = await generate_message_proof()
    const tx = await ethClient.outbound.receive_messages_delivery_proof(i, proof, overrides)
    log(tx)
    await expect(tx)
      .to.emit(ethClient.outbound, "MessagesDelivered")
      .withArgs(1, 1, 0)
  })

})
