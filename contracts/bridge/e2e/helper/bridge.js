const { BigNumber } = require("ethers");

const LANE_IDENTIFY_SLOT="0x0000000000000000000000000000000000000000000000000000000000000000"
const LANE_NONCE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000001"
const LANE_MESSAGE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000002"

const get_storage_proof = async (client, addr, storageKeys, blockNumber = 'latest') => {
  return await client.provider.send("eth_getProof",
    [
      addr,
      storageKeys,
      blockNumber
    ]
  )
}

const build_message_keys = (front, end) => {
  const keys = []
  for (let index=front; index<=end; index++) {
    const newKey = ethers.utils.concat([
      ethers.utils.hexZeroPad(index, 32),
      LANE_MESSAGE_SLOT
    ])
    const key0 = ethers.utils.keccak256(newKey)
    const key1 = BigNumber.from(key0).add(1).toHexString()
    const key2 = BigNumber.from(key0).add(2).toHexString()
    keys.push(key0)
    keys.push(key1)
    keys.push(key2)
  }
  return keys
}

const generate_storage_delivery_proof = async (client, front, end) => {
  const addr = client.inbound.address
  const laneIDProof = await get_storage_proof(client, addr, [LANE_IDENTIFY_SLOT])
  const laneNonceProof = await get_storage_proof(client, addr, [LANE_NONCE_SLOT])
  const keys = build_message_keys(front, end)
  const laneRelayersProof = await get_storage_proof(client, addr, keys)
  const proof = {
    "accountProof": laneIDProof.accountProof,
    "laneNonceProof": laneNonceProof.storageProof[0].proof,
    "laneRelayersProof": laneRelayersProof.storageProof.map((p) => p.proof),
  }
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(bytes[] accountProof, bytes[] laneNonceProof, bytes[][] laneRelayersProof)"
    ], [ proof ])
}

const generate_storage_proof = async (client, begin, end) => {
  const addr = client.outbound.address
  const laneIdProof = await get_storage_proof(client, addr, [LANE_IDENTIFY_SLOT])
  const laneNonceProof = await get_storage_proof(client, addr, [LANE_NONCE_SLOT])
  const keys = build_message_keys(begin, end)
  const laneMessageProof = await get_storage_proof(client, addr, keys)
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

const get_message_proof = async (subClient, type) => {
  const thisChainPos = await subClient.inbound.thisChainPosition()
  const bridgedChainPos = await subClient.inbound.bridgedChainPosition()
  const c0 = await subClient.chainMessageCommitter['commitment(uint256)'](thisChainPos)
  const c1 = await subClient.chainMessageCommitter['commitment(uint256)'](bridgedChainPos)
  const c = await subClient.chainMessageCommitter['commitment()']()
  const thisInLanePos = await subClient.inbound.thisLanePosition()
  const inb = await subClient.laneMessageCommitter['commitment(uint256)'](thisInLanePos)

  const thisOutLanePos = await subClient.outbound.thisLanePosition()
  const outb = await subClient.laneMessageCommitter['commitment(uint256)'](thisOutLanePos)

  let b
  if (type == 'receive') {
    b = inb
  } else if (type == 'delivery') {
    b = outb
  } else {
    return new Error(`Invalid type: ${type}`);
  }
  const chainProof = {
    root: c,
    count: 2,
    proof: [c0]
  }
  const laneProof = {
    root: c1,
    count: 2,
    proof: [b]
  }
  return {chainProof, laneProof}
}

const generate_message_proof = async (subClient, type) => {
  const proof = await get_message_proof(subClient, type)
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(tuple(bytes32,uint256,bytes32[]),tuple(bytes32,uint256,bytes32[]))"
    ], [
      [
        [proof.chainProof.root, proof.chainProof.count, proof.chainProof.proof],
        [proof.laneProof.root, proof.laneProof.count, proof.laneProof.proof]
      ]
    ])
}
/**
 * The Mock Bridge for testing
 */
class Bridge {
  constructor(ethClient, subClient) {
    this.ethClient = ethClient
    this.subClient = subClient
  }

  async enroll_relayer() {
    await this.ethClient.enroll_relayer()
    await this.subClient.enroll_relayer()
  }

  async deposit() {
    await this.ethClient.deposit()
    await this.subClient.deposit()
  }

  async relay_eth_header() {
    const header = await this.ethClient.block_header()
    return await this.subClient.relay_header(header.stateRoot)
  }

  async relay_sub_header() {
    const header = await this.subClient.block_header()
    const message_root = await this.subClient.chainMessageCommitter['commitment()']()
    return await this.ethClient.relay_header(message_root, header.number.toString())
  }

  async relay_eth_messages(data) {
    await relay_eth_header()
    await dispatch_eth_messages(data)
    await relay_sub_header()
    await confirm_eth_messages()
  }

  async relay_sub_messages(data) {
    await relay_sub_header()
    await dispatch_sub_messages(data)
    await relay_eth_header()
    await confirm_sub_messages()
  }

  async dispatch_sub_messages(data, signer) {
    const o = await this.subClient.outbound.data()
    const proof = await generate_message_proof(this.subClient, 'receive')
    if (signer) {
      this.ethClient.inbound = this.ethClient.inbound.connect(signer)
    }
    return await this.ethClient.inbound.receive_messages_proof(o, data, proof)
  }

  async confirm_eth_messages() {
    const i = await this.subClient.inbound.data()
    const o = await this.ethClient.outbound.outboundLaneNonce()
    const proof = await generate_message_proof(this.subClient, 'delivery')
    return await this.ethClient.outbound.receive_messages_delivery_proof(i, proof)
  }

  async dispatch_eth_messages(data) {
    const o = await this.ethClient.outbound.data()
    const nonce = await this.ethClient.outbound.outboundLaneNonce()
    const begin = nonce.latest_received_nonce.add(1)
    const end = nonce.latest_generated_nonce
    const proof = await generate_storage_proof(this.ethClient, begin.toHexString(), end.toHexString())
    return await this.subClient.inbound.receive_messages_proof(o, data, proof, { gasLimit: 6000000 })
  }

  async confirm_sub_messages() {
    const i = await this.ethClient.inbound.data()
    const nonce = await this.ethClient.inbound.inboundLaneNonce()
    const proof = await generate_storage_delivery_proof(this.ethClient, nonce.relayer_range_front.toHexString(), nonce.relayer_range_back.toHexString())
    return await this.subClient.outbound.receive_messages_delivery_proof(i, proof, { gasLimit: 6000000 })
  }
}

module.exports.Bridge = Bridge
