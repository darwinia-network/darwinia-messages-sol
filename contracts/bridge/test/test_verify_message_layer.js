const { expect } = require("chai")
const { solidity } = require("ethereum-waffle")
const chai = require("chai")
// const { GetAndVerify, GetProof, VerifyProof } = require('eth-proof')

chai.use(solidity)
const log = console.log
const sourceChainPos = 0
const sourceOutLanePos = 0
const sourceInLanePos = 1
const targetChainPos = 1
const targetOutLanePos = 0
const targetInLanePos = 1
const LANE_COMMITMENT_POSITION = '0x1'
let sourceOutbound, sourceInbound
let targetOutbound, targetInbound
let darwiniaLaneCommitter0, darwiniaChainCommitter
let sourceLightClient, targetLightClient
let overrides = { value: ethers.utils.parseEther("30") }

let owner, source
const target = "0x0000000000000000000000000000000000000000"
const encoded = "0x"
const encoded_hash = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"

// let getAndVerify = new GetAndVerify("http://127.0.0.1:8545 ")

const build_proof = async (targetChainPos, sourceLanePos) => {
    return await darwiniaChainCommitter.prove(targetChainPos, sourceLanePos)
}

const generate_darwinia_proof = async () => {
  return await build_proof(targetChainPos, sourceOutLanePos)
  // return ethers.utils.defaultAbiCoder.encode([
  //   "tuple(tuple(bytes32,bytes32[]),tuple(bytes32,bytes32[]))"
  //   ], [
  //     [
  //       [proof.chainProof.root, proof.chainProof.proof],
  //       [proof.laneProof.root, proof.laneProof.proof]
  //     ]
  //   ])
}

const send_message = async (outbound, nonce) => {
    const tx = await outbound.send_message(
      target,
      encoded,
      overrides
    )
    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(nonce, source, target, encoded)
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

const receive_messages_proof = async (inbound, srcoutbound, srcinbound, nonce) => {
    const o = await srcoutbound.data()
    const data = build_land_data(o)
    const proof = await generate_darwinia_proof()
    const from = (await inbound.inboundLaneNonce()).last_delivered_nonce.toNumber()
    const size = nonce - from
    const tx = await inbound.receive_messages_proof(data, proof)
    for (let i = 0; i<size; i++) {
      await expect(tx)
        .to.emit(inbound, "MessageDispatched")
        .withArgs(from+i+1, false)
    }
}

const receive_messages_delivery_proof = async (outbound, tgtoutbound, tgtinbound, begin, end) => {
    const i = await tgtinbound.data()
    // const proof = await generate_bsc_proof()
    const tx = await outbound.receive_messages_delivery_proof(i, "0x")
    await expect(tx)
      .to.emit(outbound, "MessagesDelivered")
      .withArgs(begin, end, 0)
}

describe("verify message relay tests", () => {

  before(async () => {
    const VAULT = "0x0000000000000000000000000000000000000000"
    const COLLATERAL_PERORDER = ethers.utils.parseEther("10")
    const ASSIGNED_RELAYERS_NUMBER = 3;
    const SLASH_TIME = 100
    const RELAY_TIME = 100
    const PRICE_RATIO = 800_000
    const FeeMarket = await ethers.getContractFactory("FeeMarket")
    const feeMarket = await FeeMarket.deploy(VAULT, COLLATERAL_PERORDER, ASSIGNED_RELAYERS_NUMBER, SLASH_TIME, RELAY_TIME, PRICE_RATIO)

    const [owner] = await ethers.getSigners();
    source = owner.address
    const MockBSCLightClient = await ethers.getContractFactory("MockBSCLightClient")
    const MockDarwiniaLightClient = await ethers.getContractFactory("MockDarwiniaLightClient")
    const OutboundLane = await ethers.getContractFactory("OutboundLane")
    const InboundLane = await ethers.getContractFactory("InboundLane")
    const ChainMessageCommitter = await ethers.getContractFactory("ChainMessageCommitter")
    const LaneMessageCommitter = await ethers.getContractFactory("LaneMessageCommitter")

    targetLightClient = await MockBSCLightClient.deploy(LANE_COMMITMENT_POSITION)
    sourceOutbound = await OutboundLane.deploy(targetLightClient.address, feeMarket.address, sourceChainPos, sourceOutLanePos, targetChainPos, targetInLanePos, 1, 0, 0)
    sourceInbound = await InboundLane.deploy(targetLightClient.address, sourceChainPos, sourceInLanePos, targetChainPos, targetOutLanePos, 0, 0)
    darwiniaLaneCommitter0 = await LaneMessageCommitter.deploy(sourceChainPos, targetChainPos)
    await darwiniaLaneCommitter0.registry(sourceOutbound.address, sourceInbound.address)
    darwiniaChainCommitter = await ChainMessageCommitter.deploy(sourceChainPos)
    await darwiniaChainCommitter.registry(darwiniaLaneCommitter0.address)

    sourceLightClient = await MockDarwiniaLightClient.deploy()
    targetOutbound = await OutboundLane.deploy(sourceLightClient.address, feeMarket.address, targetChainPos, targetOutLanePos, sourceChainPos, sourceInLanePos, 1, 0, 0)
    targetInbound = await InboundLane.deploy(sourceLightClient.address, targetChainPos, targetInLanePos, sourceChainPos, sourceOutLanePos, 0, 0)

    await targetLightClient.setBound(sourceChainPos, targetOutLanePos, targetOutbound.address, targetInLanePos, targetInbound.address)

    const [one, two, three] = await ethers.getSigners();
    let overrides = {
        value: ethers.utils.parseEther("100")
    }
    const [oneFee, twoFee, threeFee] = [
      ethers.utils.parseEther("10"),
      ethers.utils.parseEther("20"),
      ethers.utils.parseEther("30")
    ]
    await feeMarket.connect(one).enroll("0x0000000000000000000000000000000000000001", oneFee, overrides)
    await feeMarket.connect(two).enroll(one.address, twoFee, overrides)
    await feeMarket.connect(three).enroll(two.address, threeFee, overrides)

    await feeMarket.setOutbound(sourceOutbound.address, 1)
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
  //   let position        = LANE_COMMITMENT_POSITION
  //   let storageValue = await getAndVerify.storageAgainstBlockHash(accountAddress, position, blockHash)
  //   let v = '0x' + storageValue.toString('hex')
  //   expect(v).to.equal(c)
  // });

});
