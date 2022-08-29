const { BigNumber } = require("ethers")
const { toHexString } = require('@chainsafe/ssz')
const rlp = require("rlp")

const LANE_IDENTIFY_SLOT="0x0000000000000000000000000000000000000000000000000000000000000000"
const LANE_NONCE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000001"
const LANE_MESSAGE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000002"

const get_storage_proof = async (client, addr, storageKeys, blockNumber = 'latest') => {
  if (blockNumber != 'latest') {
    blockNumber = "0x" + Number(blockNumber).toString(16)
  }
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
    keys.push(ethers.utils.keccak256(newKey))
  }
  return keys
}

const build_relayer_keys = (front, end) => {
  const keys = []
  for (let index=front; index<=end; index++) {
    const newKey = ethers.utils.concat([
      ethers.utils.hexZeroPad(index, 32),
      LANE_MESSAGE_SLOT
    ])
    const key0 = ethers.utils.keccak256(newKey)
    const key1 = BigNumber.from(key0).add(1).toHexString()
    keys.push(key0)
    keys.push(key1)
  }
  return keys
}

const generate_storage_delivery_proof = async (client, front, end, block_number) => {
  const addr = client.inbound.address
  const laneIDProof = await get_storage_proof(client, addr, [LANE_IDENTIFY_SLOT], block_number)
  const laneNonceProof = await get_storage_proof(client, addr, [LANE_NONCE_SLOT], block_number)
  const keys = build_relayer_keys(front, end)
  const laneRelayersProof = await get_storage_proof(client, addr, keys, block_number)
  const proof = {
    "accountProof": toHexString(rlp.encode(laneIDProof.accountProof)),
    "laneNonceProof": toHexString(rlp.encode(laneNonceProof.storageProof[0].proof)),
    "laneRelayersProof": laneRelayersProof.storageProof.map((p) => toHexString(rlp.encode(p.proof))),
  }
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(bytes accountProof, bytes laneNonceProof, bytes[] laneRelayersProof)"
    ], [ proof ])
}

const generate_storage_proof = async (client, begin, end, block_number) => {
  const addr = client.outbound.address
  const laneIdProof = await get_storage_proof(client, addr, [LANE_IDENTIFY_SLOT], block_number)
  const laneNonceProof = await get_storage_proof(client, addr, [LANE_NONCE_SLOT], block_number)
  const keys = build_message_keys(begin, end)
  const laneMessageProof = await get_storage_proof(client, addr, keys, block_number)
  const proof = {
    "accountProof": toHexString(rlp.encode(laneIdProof.accountProof)),
    "laneIDProof": toHexString(rlp.encode(laneIdProof.storageProof[0].proof)),
    "laneNonceProof": toHexString(rlp.encode(laneNonceProof.storageProof[0].proof)),
    "laneMessagesProof": laneMessageProof.storageProof.map((p) => toHexString(rlp.encode(p.proof))),
  }
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(bytes accountProof, bytes laneIDProof, bytes laneNonceProof, bytes[] laneMessagesProof)"
    ], [ proof ])
}

const generate_message_proof = async (chain_committer, lane_committer, lane_pos, block_number) => {
  const bridgedChainPos = await lane_committer.bridgedChainPosition()
  const proof = await chain_committer.prove(bridgedChainPos, lane_pos, {
    blockNumber: block_number
  })
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(tuple(bytes32,bytes32[]),tuple(bytes32,bytes32[]))"
    ], [
      [
        [proof.chainProof.root, proof.chainProof.proof],
        [proof.laneProof.root, proof.laneProof.proof]
      ]
    ])
}

/**
 * The Mock Bridge for testing
 */
class Bridge {
  constructor(ethClient, bscClient, eth2Client, subClient) {
    this.ethClient = ethClient
    this.bscClient = bscClient
    this.eth2Client = eth2Client
    this.subClient = subClient
    this.eth = ethClient
    this.bsc = bscClient
    this.sub = subClient
  }

  async enroll_relayer() {
    await this.eth.enroll_relayer()
    await this.bsc.enroll_relayer()
    await this.sub.eth.enroll_relayer()
    await this.sub.bsc.enroll_relayer()
  }

  async deposit() {
    await this.eth.deposit()
    await this.sub.deposit()
    await this.sub.eth.deposit()
    await this.sub.bsc.deposit()
  }

  async relay_eth_header() {
    const old_finalized_header = await this.subClient.beaconLightClient.finalized_header()
    const finality_update = await this.eth2Client.get_finality_update()
    let attested_header = finality_update.attested_header
    let finalized_header = finality_update.finalized_header
    const period = Number(finalized_header.slot) / 32 / 256
    const sync_change = await this.eth2Client.get_sync_committee_period_update(~~period - 1, 1)
    const next_sync = sync_change[0]
    const current_sync_committee = next_sync.next_sync_committee

    let sync_aggregate_slot = Number(attested_header.slot) + 1
    let sync_aggregate_header = await this.eth2Client.get_header(sync_aggregate_slot)
    while (!sync_aggregate_header) {
      sync_aggregate_slot = Number(sync_aggregate_slot) + 1
      sync_aggregate_header = await this.eth2Client.get_header(sync_aggregate_slot)
    }

    const fork_version = await this.eth2Client.get_fork_version(sync_aggregate_slot)

    let sync_aggregate = finality_update.sync_aggregate
    let sync_committee_bits = []
    sync_committee_bits.push(sync_aggregate.sync_committee_bits.slice(0, 66))
    sync_committee_bits.push('0x' + sync_aggregate.sync_committee_bits.slice(66))
    sync_aggregate.sync_committee_bits = sync_committee_bits;

    const finalized_header_update = {
      attested_header: attested_header,
      signature_sync_committee: current_sync_committee,
      finalized_header: finalized_header,
      finality_branch: finality_update.finality_branch,
      sync_aggregate: sync_aggregate,
      fork_version: fork_version.current_version,
      signature_slot: sync_aggregate_slot
    }

    const tx = await this.subClient.beaconLightClient.import_finalized_header(finalized_header_update,
      {
        gasPrice: 1000000000,
        gasLimit: 5000000
      })

    // const new_finalized_header = await this.subClient.beaconLightClient.finalized_header()
  }

  async relay_eth_execution_payload() {
    const finalized_header = await this.subClient.beaconLightClient.finalized_header()
    const finalized_block = await this.eth2Client.get_beacon_block(finalized_header.slot)

    const latest_execution_payload_state_root = finalized_block.message.body.execution_payload.state_root
    const latest_execution_payload_state_root_branch = await this.eth2Client.get_latest_execution_payload_state_root_branch(finalized_header.slot)

    const execution_payload_state_root_update = {
      latest_execution_payload_state_root,
      latest_execution_payload_state_root_branch: latest_execution_payload_state_root_branch.witnesses
    }

    const tx = await this.subClient.executionLayer.import_latest_execution_payload_state_root(execution_payload_state_root_update)
    const state_root = await this.subClient.executionLayer.merkle_root()
    console.log(state_root)
  }

  async relay_bsc_header() {
    const old_finalized_checkpoint = await this.subClient.bscLightClient.finalized_checkpoint()
    const finalized_checkpoint_number = old_finalized_checkpoint.number.add(200)
    const finalized_checkpoint = await this.bscClient.get_block('0x' + finalized_checkpoint_number.toNumber().toString(16))
    const length = await this.subClient.bscLightClient.length_of_finalized_authorities()
    let headers = [finalized_checkpoint]
    let number = finalized_checkpoint_number
    for (let i=0; i < ~~length.div(2); i++) {
      number = number.add(1)
      const header = await this.bscClient.get_block('0x' + number.toNumber().toString(16))
      headers.push(header)
    }
    const tx = await this.subClient.bscLightClient.import_finalized_epoch_header(headers)
    console.log(tx)
  }

  async relay_sub_header() {
    const header = await this.sub.block_header()
    const message_root = await this.sub.chainMessageCommitter['commitment()']()
    const nonce = await this.sub.ecdsa_authority_nonce(header.hash)
    const block_number = header.number.toNumber()
    const message = {
      block_number,
      message_root,
      nonce: nonce.toNumber()
    }
    const signs = await this.sub.sign_message_commitment(message)
    await this.eth.ecdsa_relay_header(message, signs)
    await this.bsc.ecdsa_relay_header(message, signs)
    return await this.ethClient.relay_header(message_root, header.number.toString())
  }

  async relay_eth_messages(data) {
    await relay_eth_header()
    await dispatch_messages_to_sub('eth', data)
    await relay_sub_header()
    await confirm_messages_to_sub('eth')
  }

  async relay_sub_messages_to_eth(data) {
    await relay_sub_header()
    await dispatch_messages_from_sub('eth', data)
    await relay_eth_header()
    await confirm_messages_from_sub('eth')
  }

  async dispatch_messages_from_sub(to, data) {
    const c = this[to]
    const info = await this.sub[to].outbound.getLaneInfo()
    const finality_block_number = await c.lightClient.block_number()
    const proof = await generate_message_proof(this.sub.chainMessageCommitter, this.sub[to].LaneMessageCommitter, info[1])
    return await c.inbound.receive_messages_proof(data, proof)
  }

  async confirm_messages_from_sub(to) {
    const c = this[to]
    const i = await c.inbound.data()
    const nonce = await c.inbound.inboundLaneNonce()
    const finality_block_number = await this.finality_block_number(to)
    const front = nonce.relayer_range_front.toHexString()
    const end = nonce.relayer_range_back.toHexString()
    const proof = await generate_storage_delivery_proof(c, front, end, finality_block_number)
    return await this.sub[to].outbound.receive_messages_delivery_proof(i, proof, { gasLimit: 6000000 })
  }

  async dispatch_messages_to_sub(from, data) {
    const c = this[from]
    const nonce = await c.outbound.outboundLaneNonce()
    const begin = nonce.latest_received_nonce.add(1).toHexString()
    const end = nonce.latest_generated_nonce.toHexString()
    const finality_block_number = await this.finality_block_number(from)
    const proof = await generate_storage_proof(c, begin, end, finality_block_number)
    return this.sub[from].inbound.receive_messages_proof(data, proof, { gasLimit: 6000000 })
  }

  async confirm_messages_to_sub(from) {
    const c = this[from]
    const i = await this.sub[from].inbound.data()
    const info = await this.sub[from].inbound.getLaneInfo()
    const o = await c.outbound.outboundLaneNonce()
    const finality_block_number = c.lightClient.block_number()
    const proof = await generate_message_proof(this.sub.chainMessageCommitter, this.sub[from].LaneMessageCommitter, info[1])
    return await c.outbound.receive_messages_delivery_proof(i, proof)
  }

  async finality_block_number(from) {
    if (from == 'eth') {
      const finalized_header = await this.sub.beaconLightClient.finalized_header()
      const finality_block = await this.eth2Client.get_beacon_block(finalized_header.slot)
      return finality_block.message.body.execution_payload.block_number
    } else if (from == 'bsc') {
      const finalized_header = await this.subClient.bscLightClient.finalized_checkpoint()
      return finalized_header.number
    } else { throw new Error("invalid from") }
  }
}

module.exports.Bridge = Bridge
