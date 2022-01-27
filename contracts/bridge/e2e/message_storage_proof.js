const { expect } = require("chai")
const { waffle } = require("hardhat");
const { BigNumber } = require("ethers");
const { bootstrap } = require("./helper/fixture")
const chai = require("chai")
const { solidity } = waffle;

chai.use(solidity)
const log = console.log
const LANE_IDENTIFY_SLOT="0x0000000000000000000000000000000000000000000000000000000000000000"
const LANE_NONCE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000001"
const LANE_MESSAGE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000002"
const overrides = { value: ethers.utils.parseEther("30") }
let ethClient, subClient

const get_storage_proof = async (addr, storageKeys, blockNumber = 'latest') => {
  return await ethClient.provider.send("eth_getProof",
    [
      addr,
      storageKeys,
      blockNumber
    ]
  )
}

const generate_storage_proof = async (begin, end) => {
  const addr = ethClient.outbound.address
  const laneIdProof = await get_storage_proof(addr, [LANE_IDENTIFY_SLOT])
  const laneNonceProof = await get_storage_proof(addr, [LANE_NONCE_SLOT])
  const keys = []
  for (let index=begin; index<=end; index++) {
    const newKeyPreimage = ethers.utils.concat([
        ethers.utils.hexZeroPad(index, 32),
        LANE_MESSAGE_SLOT,
    ])
    const key0 = ethers.utils.keccak256(newKeyPreimage)
    const key1 = BigNumber.from(key0).add(1).toHexString()
    const key2 = BigNumber.from(key0).add(2).toHexString()
    keys.push(key0)
    keys.push(key1)
    keys.push(key2)
  }
  const laneMessageProof = await get_storage_proof(addr, keys)
  const proof = {
    "accountProof": laneIdProof.accountProof,
    "laneIDProof": laneIdProof.storageProof[0].proof,
    "laneNonceProof": laneNonceProof.storageProof[0].proof,
    "laneMessagesProof": laneMessageProof.storageProof.map((p) => p.proof),
  }
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(bytes[] accountProof, bytes[] laneIDProof, bytes[] laneNonceProof, bytes[][] laneMessagesProof)"
    ], [ proof ])
}

const generate_storage_delivery_proof = async (front, end) => {
  const addr = ethClient.inbound.address
  const laneIDProof = await get_storage_proof(addr, [LANE_IDENTIFY_SLOT])
  const laneNonceProof = await get_storage_proof(addr, [LANE_NONCE_SLOT])
  const keys = []
  for (let index=front; index<=end; index++) {
    const newKeyPreimage = ethers.utils.concat([
      ethers.utils.hexZeroPad(index, 32),
      LANE_MESSAGE_SLOT
    ])
    const key0 = ethers.utils.keccak256(newKeyPreimage)
    const key1 = BigNumber.from(key0).add(1).toHexString()
    const key2 = BigNumber.from(key0).add(2).toHexString()
    keys.push(key0)
    keys.push(key1)
    keys.push(key2)
  }
  const laneRelayersProof = await get_storage_proof(addr, keys)
  const proof = {
    "accountProof": laneIDProof.accountProof,
    "laneNonceProof": laneNonceProof.storageProof[0].proof,
    "laneRelayersProof": laneRelayersProof.storageProof.map((p) => p.proof),
  }
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(bytes[] accountProof, bytes[] laneNonceProof, bytes[][] laneRelayersProof)"
    ], [ proof ])
}

const get_message_delivery_proof = async () => {
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

const generate_message_delivery_proof = async () => {
  const proof = await get_message_delivery_proof()
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(tuple(bytes32,uint256,bytes32[]),tuple(bytes32,uint256,bytes32[]))"
    ], [
      [
        [proof.chainProof.root, proof.chainProof.count, proof.chainProof.proof],
        [proof.laneProof.root, proof.laneProof.count, proof.laneProof.proof]
      ]
    ])
}

const get_message_proof = async () => {
  const thisChainPos = await subClient.inbound.thisChainPosition()
  const bridgedChainPos = await subClient.inbound.bridgedChainPosition()
  const c0 = await subClient.chainMessageCommitter['commitment(uint256)'](thisChainPos)
  const c1 = await subClient.chainMessageCommitter['commitment(uint256)'](bridgedChainPos)
  const c = await subClient.chainMessageCommitter['commitment()']()
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
    "tuple(tuple(bytes32,uint256,bytes32[]),tuple(bytes32,uint256,bytes32[]))"
    ], [
      [
        [proof.chainProof.root, proof.chainProof.count, proof.chainProof.proof],
        [proof.laneProof.root, proof.laneProof.count, proof.laneProof.proof]
      ]
    ])
}

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}


describe("bridge e2e test: verify message/storage proof", () => {

  before(async () => {
  })

  it("bootstrap", async () => {
    const clients = await bootstrap()
    ethClient = clients.ethClient
    subClient = clients.subClient
  })

  it("enroll", async () => {
    await ethClient.enroll_relayer()
    await subClient.enroll_relayer()
  })

  it("deposit", async () => {
    await ethClient.deposit()
    await subClient.deposit()
  })

  it("0.1", async function () {
    const nonce = await ethClient.outbound.outboundLaneNonce()
    const tx = await ethClient.outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x",
      overrides
    )
    await expect(tx)
      .to.emit(ethClient.outbound, "MessageAccepted")
      .withArgs(nonce.latest_generated_nonce.add(1), "0x")
  })

  it("0.2", async function () {
    const nonce = await ethClient.outbound.outboundLaneNonce()
    const tx = await ethClient.outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x",
      overrides
    )
    await expect(tx)
      .to.emit(ethClient.outbound, "MessageAccepted")
      .withArgs(nonce.latest_generated_nonce.add(1), "0x")
  })

  it("1", async function () {
    const header = await ethClient.block_header()
    await subClient.relay_header(header.stateRoot)
    await sleep(3000)
  })

  it("2", async function () {
    await sleep(3000)
    const o = await ethClient.outbound.data()
    const calldata = Array(o.messages.length).fill("0x")
    const nonce = await ethClient.outbound.outboundLaneNonce()
    const begin = nonce.latest_received_nonce.add(1)
    const end = nonce.latest_generated_nonce
    const proof = await generate_storage_proof(begin.toHexString(), end.toHexString())
    const tx = await subClient.inbound.receive_messages_proof(o, calldata, proof, { gasLimit: 10000000 })
    for (let i=begin; i<=end; i++) {
      await expect(tx)
        .to.emit(subClient.inbound, "MessageDispatched")
        .withArgs(
          await ethClient.outbound.thisChainPosition(),
          await ethClient.outbound.thisLanePosition(),
          await ethClient.outbound.bridgedChainPosition(),
          await ethClient.outbound.bridgedLanePosition(),
          i,
          false,
          "0x4c616e653a204d65737361676543616c6c52656a6563746564"
        )
    }
  })

  it("3", async function () {
    const header = await subClient.block_header()
    const message_root = await subClient.chainMessageCommitter['commitment()']()
    await ethClient.relay_header(message_root, header.number.toString())
  })

  it("4", async function () {
    const i = await subClient.inbound.data()
    const o = await ethClient.outbound.outboundLaneNonce()
    const proof = await generate_message_delivery_proof()
    const tx = await ethClient.outbound.receive_messages_delivery_proof(i, proof)
    await expect(tx)
      .to.emit(ethClient.outbound, "MessagesDelivered")
      .withArgs(o.latest_received_nonce.add(1), i.last_delivered_nonce, 0)
  })

  it("5", async function () {
    const nonce = await subClient.outbound.outboundLaneNonce()
    const tx = await subClient.outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x",
      overrides
    )

    await expect(tx)
      .to.emit(subClient.outbound, "MessageAccepted")
      .withArgs(nonce.latest_generated_nonce.add(1), "0x")
  })

  it("6", async function () {
    const header = await subClient.block_header()
    const message_root = await subClient.chainMessageCommitter['commitment()']()
    await ethClient.relay_header(message_root, header.number.toString())
  })

  it("7", async function () {
    const o = await subClient.outbound.data()
    const calldata = Array(o.messages.length).fill("0x")
    const proof = await generate_message_proof()
    const begin = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce.add(1)
    const tx = await ethClient.inbound.receive_messages_proof(o, calldata, proof)
    const end = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce
    for (let i=begin; i<=end; i++) {
      await expect(tx)
        .to.emit(ethClient.inbound, "MessageDispatched")
        .withArgs(
          await subClient.outbound.thisChainPosition(),
          await subClient.outbound.thisLanePosition(),
          await subClient.outbound.bridgedChainPosition(),
          await subClient.outbound.bridgedLanePosition(),
          i,
          false,
          "0x4c616e653a204d65737361676543616c6c52656a6563746564"
        )
    }
  })

  it("8", async function () {
    const nonce = await subClient.outbound.outboundLaneNonce()
    const tx = await subClient.outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x",
      overrides
    )

    await expect(tx)
      .to.emit(subClient.outbound, "MessageAccepted")
      .withArgs(nonce.latest_generated_nonce.add(1), "0x")
  })

  it("9", async function () {
    const header = await subClient.block_header()
    const message_root = await subClient.chainMessageCommitter['commitment()']()
    await ethClient.relay_header(message_root, header.number.toString())
  })

  it("10", async function () {
    const o = await subClient.outbound.data()
    const calldata = Array(o.messages.length).fill("0x")
    const proof = await generate_message_proof()
    const begin = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce.add(1)
    let signer = ethClient.get_signer(1)
    const tx = await ethClient.inbound.connect(signer).receive_messages_proof(o, calldata, proof)
    const end = (await subClient.inbound.inboundLaneNonce()).last_delivered_nonce
    for (let i=begin; i<=end; i++) {
      await expect(tx)
        .to.emit(ethClient.inbound, "MessageDispatched")
        .withArgs(
          await subClient.outbound.thisChainPosition(),
          await subClient.outbound.thisLanePosition(),
          await subClient.outbound.bridgedChainPosition(),
          await subClient.outbound.bridgedLanePosition(),
          i,
          false,
          "0x4c616e653a204d65737361676543616c6c52656a6563746564"
        )
    }
  })

  it("11", async function () {
    const header = await ethClient.block_header()
    await subClient.relay_header(header.stateRoot)
    await sleep(3000)
  })

  it("12", async function () {
    await sleep(3000)
    const i = await ethClient.inbound.data()
    const nonce = await ethClient.inbound.inboundLaneNonce()
    const o = await subClient.outbound.outboundLaneNonce()
    const proof = await generate_storage_delivery_proof(nonce.relayer_range_front.toHexString(), nonce.relayer_range_back.toHexString())
    const tx = await subClient.outbound.receive_messages_delivery_proof(i, proof, { gasLimit: 6000000 })
    await expect(tx)
      .to.emit(subClient.outbound, "MessagesDelivered")
      .withArgs(o.latest_received_nonce.add(1), i.last_delivered_nonce, 0)
  })
})
