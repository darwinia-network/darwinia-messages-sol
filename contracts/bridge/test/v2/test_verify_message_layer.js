const { expect } = require("chai")
const { solidity } = require("ethereum-waffle")
const chai = require("chai")
// const { GetAndVerify, GetProof, VerifyProof } = require('eth-proof')

chai.use(solidity)
const log = console.log
const sourceChainPos = 0
const targetChainPos = 1
const lanePos = 0
const OUTBOUND_COMMITMENT_POSITION = '0x1'
const INBOUND_COMMITMENT_POSITION = '0x1'
let sourceOutbound, sourceInbound
let targetOutbound, targetInbound
let darwiniaLaneCommitter0, darwiniaChainCommitter
let sourceLightClient, targetLightClient

// let getAndVerify = new GetAndVerify("http://127.0.0.1:8545 ")

const build_proof = async () => {
    const c0 = await darwiniaChainCommitter['commitment(uint256)'](sourceChainPos)
    const c1 = await darwiniaChainCommitter['commitment(uint256)'](targetChainPos)
    const c = await darwiniaChainCommitter['commitment()']()
    const chainProof = {
      root: c,
      count: 2,
      proof: [c0]
    }
    const laneProof = {
      root: c1,
      count: 1,
      proof: []
    }
    return { chainProof, laneProof }
}

const generate_darwinia_proof = async () => {
  const proof = await build_proof()
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(tuple(bytes32,uint256,bytes32[]),tuple(bytes32,uint256,bytes32[]))"
    ], [
      [
        [proof.chainProof.root, proof.chainProof.count, proof.chainProof.proof],
        [proof.laneProof.root, proof.laneProof.count, proof.laneProof.proof]
      ]
    ])
}

const send_message = async (outbound, nonce) => {
    const tx = await outbound.send_message(
      "0x0000000000000000000000000000000000000000",
      "0x"
    )
    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(nonce)
}

const receive_messages_proof = async (inbound, srcoutbound, srcinbound, nonce) => {
    const o = await srcoutbound.data()
    const i = await srcinbound.commitment()
    const proof = await generate_darwinia_proof()
    const tx = await inbound.receive_messages_proof(o, i, proof)
    const n = await inbound.inboundLaneNonce()
    const size = n.last_delivered_nonce - nonce
    for (let i = 0; i<size; i++) {
      await expect(tx)
        .to.emit(inbound, "MessageDispatched")
        .withArgs(bridgedChainPos, thisChainPos, lanePos, nonce+i, false, "0x4c616e653a204d65737361676543616c6c52656a6563746564")
    }
}

const receive_messages_delivery_proof = async (outbound, tgtoutbound, tgtinbound, begin, end) => {
    const i = await tgtinbound.data()
    const o = await tgtoutbound.commitment()
    // const proof = await generate_bsc_proof()
    const tx = await outbound.receive_messages_delivery_proof(o, i, "0x")
    await expect(tx)
      .to.emit(outbound, "MessagesDelivered")
      .withArgs(begin, end, 0)
}

describe("verify message relay tests", () => {

  before(async () => {
    const [owner] = await ethers.getSigners();
    const BSCLightClientMock = await ethers.getContractFactory("BSCLightClientMock")
    const MockDarwiniaLightClient = await ethers.getContractFactory("MockDarwiniaLightClient")
    const OutboundLane = await ethers.getContractFactory("OutboundLane")
    const InboundLane = await ethers.getContractFactory("InboundLane")
    const ChainMessageCommitter = await ethers.getContractFactory("ChainMessageCommitter")
    const LaneMessageCommitter = await ethers.getContractFactory("LaneMessageCommitter")

    targetLightClient = await BSCLightClientMock.deploy(OUTBOUND_COMMITMENT_POSITION, INBOUND_COMMITMENT_POSITION)
    sourceOutbound = await OutboundLane.deploy(targetLightClient.address, sourceChainPos, targetChainPos, lanePos, 1, 0, 0)
    await sourceOutbound.grantRole("0x7bb193391dc6610af03bd9922e44c83b9fda893aeed61cf64297fb4473500dd1", owner.address)
    sourceInbound = await InboundLane.deploy(targetLightClient.address, sourceChainPos, targetChainPos, lanePos, 0, 0)
    darwiniaLaneCommitter0 = await LaneMessageCommitter.deploy(sourceChainPos, targetChainPos)
    await darwiniaLaneCommitter0.registry(sourceInbound.address, sourceOutbound.address)
    darwiniaChainCommitter = await ChainMessageCommitter.deploy(sourceChainPos)
    await darwiniaChainCommitter.registry(darwiniaLaneCommitter0.address)

    sourceLightClient = await MockDarwiniaLightClient.deploy()
    targetOutbound = await OutboundLane.deploy(sourceLightClient.address, targetChainPos, sourceChainPos, lanePos, 1, 0, 0)
    await targetOutbound.grantRole("0x7bb193391dc6610af03bd9922e44c83b9fda893aeed61cf64297fb4473500dd1", owner.address)
    targetInbound = await InboundLane.deploy(sourceLightClient.address, targetChainPos, sourceChainPos, lanePos, 0, 0)

    await targetLightClient.setBound(sourceChainPos, lanePos, targetInbound.address, targetOutbound.address)
  });

  it("0", async function () {
    await send_message(sourceOutbound, 1)
  });

  it("1", async function () {
    const c = await darwiniaChainCommitter['commitment()']()
    await sourceLightClient.relayHeader(c)
  });

  it("2", async function () {
    await receive_messages_proof(targetInbound, sourceOutbound, sourceInbound, 1)
  });

  it("3", async function () {
    let c = await targetInbound['commitment()']()
    await targetLightClient.relayHeader(c)
  });

  it("4", async function () {
    await receive_messages_delivery_proof(sourceOutbound, targetOutbound, targetInbound, 1, 1)
  });

  it("5", async function () {
    const c = await darwiniaChainCommitter['commitment()']()
    await sourceLightClient.relayHeader(c)
  });

  it("6", async function () {
    await receive_messages_proof(targetInbound, sourceOutbound, sourceInbound, 1)
  });

  // it('storage verify', async () => {
  //   let c = await targetInbound['commitment()']()
  //   let block = await ethers.provider.getBlock()
  //   let blockHash = block.hash
  //   let accountAddress  = targetInbound.address
  //   let position        = INBOUND_COMMITMENT_POSITION
  //   let storageValue = await getAndVerify.storageAgainstBlockHash(accountAddress, position, blockHash)
  //   let v = '0x' + storageValue.toString('hex')
  //   expect(v).to.equal(c)
  // });

});
