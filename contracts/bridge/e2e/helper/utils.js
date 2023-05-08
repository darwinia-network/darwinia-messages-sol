const { toHexString, ListCompositeType, ByteVectorType, ByteListType } = require('@chainsafe/ssz')

const LANE_IDENTIFY_SLOT="0x0000000000000000000000000000000000000000000000000000000000000000"
const LANE_NONCE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000001"
const LANE_MESSAGE_SLOT="0x0000000000000000000000000000000000000000000000000000000000000002"

const LANE_ROOT_SLOT="0x0000000000000000000000000000000000000000000000000000000000000001"

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
    "accountProof": laneIDProof.accountProof,
    "laneNonceProof": laneNonceProof.storageProof[0].proof,
    "laneRelayersProof": laneRelayersProof.storageProof.map((p) => p.proof),
  }
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(bytes[] accountProof, bytes[] laneNonceProof, bytes[][] laneRelayersProof)"
    ], [ proof ])
}

const generate_storage_proof = async (client, begin, end, block_number) => {
  const addr = client.outbound.address
  const laneIdProof = await get_storage_proof(client, addr, [LANE_IDENTIFY_SLOT], block_number)
  const laneNonceProof = await get_storage_proof(client, addr, [LANE_NONCE_SLOT], block_number)
  const keys = build_message_keys(begin, end)
  const laneMessageProof = await get_storage_proof(client, addr, keys, block_number)
  const proof = {
    "accountProof": laneIdProof.accountProof,
    "laneNonceProof": laneNonceProof.storageProof[0].proof,
    "laneMessagesProof": laneMessageProof.storageProof.map((p) => p.proof),
  }
  return ethers.utils.defaultAbiCoder.encode([
    "tuple(bytes[] accountProof, bytes[] laneNonceProof, bytes[][] laneMessagesProof)"
    ], [ proof ])
}

const generate_parallel_lane_storage_proof = async (client, block_number) => {
  const addr = client.parallel_outbound.address
  const laneRootProof = await get_storage_proof(client, addr, [LANE_ROOT_SLOT], block_number)
  const proof = {
    "accountProof": laneRootProof.accountProof,
    "laneRootProof": laneRootProof.storageProof[0].proof
  }
  const p = ethers.utils.defaultAbiCoder.encode([
    "tuple(bytes[] accountProof, bytes[] laneRootProof)"
  ], [ proof ])
  return {
    proof: p,
    root: laneRootProof.storageProof[0].value
  }
}

const generate_message_proof = async (chain_committer, lane_committer, lane_pos, block_number) => {
  const bridgedChainPos = await lane_committer.BRIDGED_CHAIN_POSITION()
  const proof = await chain_committer.prove(bridgedChainPos, lane_pos, {
    blockTag: block_number
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

const get_ssz_type = (forks, sszTypeName, forkName) => {
  return forks[forkName][sszTypeName]
}

const hash_tree_root = (forks, sszTypeName, forkName, input) => {
  const type = get_ssz_type(forks, sszTypeName, forkName)
  const value = type.fromJson(input)
  return toHexString(type.hashTreeRoot(value))
}

const hash = (typ, input) => {
  const value = typ.fromJson(input)
  return toHexString(typ.hashTreeRoot(value))
}

const convert_logs_bloom = (input) => {
    const LogsBloom = new ByteVectorType(256)
    return hash(LogsBloom, input)
}

const convert_extra_data = (input) => {
    const ExtraData = new ByteListType(32)
    return hash(ExtraData, input)
}

const fetch_old_msgs = (from) => {
  if (from == 'eth') {
    const msg0 = {
      encoded_key: "0x0000000000000000000000010000000200000000000000030000000000000000",
      payload: {
        source: '0x3DFe30fb7b46b99e234Ed0F725B5304257F78992',
        target: '0x0000000000000000000000000000000000000000',
        encoded: '0x'
      }
    }
    const msg1 = {
      encoded_key: "0x0000000000000000000000010000000200000000000000030000000000000001",
      payload: {
        source: '0x3DFe30fb7b46b99e234Ed0F725B5304257F78992',
        target: '0x4DBdC9767F03dd078B5a1FC05053Dd0C071Cc005',
        encoded: '0x'
      }
    }
    return [messageHash(msg0), messageHash(msg1)]
  } else {
    const msg0 = {
      encoded_key: "0x0000000000000000000000000000000200000001000000030000000000000000",
      payload: {
        source: '0x3DFe30fb7b46b99e234Ed0F725B5304257F78992',
        target: '0xbB8Ac813748e57B6e8D2DfA7cB79b641bD0524c1',
        encoded: '0x'
      }
    }
    return []
  }
}

const compute_fork_version = (epoch) => {
  const target  = process.env.TARGET || 'local'
  if(target == 'local' || target == 'prod') throw new Error("no config")
  else if (target == 'test') {
    if(epoch >= 162304)
        return "0x03001020"
    if(epoch >= 112260)
        return "0x02001020"
    if(epoch >= 36660)
        return "0x01001020"
    return "0x00001020"
  }
}


module.exports = {
  get_storage_proof,
  build_message_keys,
  build_relayer_keys,
  generate_storage_delivery_proof,
  generate_storage_proof,
  generate_parallel_lane_storage_proof,
  generate_message_proof,
  fetch_old_msgs,
  compute_fork_version,
  convert_logs_bloom,
  convert_extra_data,
}
