const fetch = require('node-fetch')
const {deserializeProof} = require('@chainsafe/persistent-merkle-tree')
const {toHexString} = require('@chainsafe/ssz')


class Eth2Client {

  constructor(endopoint) {
    this.endopoint = endopoint
  }

  async get_finalized_header() {
    return await this.get_header('finalized')
  }

  async get_header(id) {
    const url = `${this.endopoint}/eth/v1/beacon/headers/${id}`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    return data.data
  }

  async get_sync_committee(epoch) {
    const url = `${this.endopoint}/eth/v1/beacon/states/finalized/sync_committees?epoch=${epoch}`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    return data.data
  }

  async get_beacon_block(id) {
    const url = `${this.endopoint}/eth/v2/beacon/blocks/${id}`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    return data.data.message
  }

  async get_beacon_block_root(id) {
    const url = `${this.endopoint}/eth/v1/beacon/blocks/${id}/root`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    return data.data.root
  }

  async get_genesis() {
    const url = `${this.endopoint}/eth/v1/beacon/genesis`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    return data
  }

  async get_fork_version(id) {
    const url = `${this.endopoint}/eth/v1/beacon/states/${id}/fork`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    return data.data
  }

  async get_finalized_checkpoint() {
    return this.get_checkpoint('finalized')
  }

  async get_checkpoint(id) {
    const url = `${this.endopoint}/eth/v1/beacon/states/${id}/finality_checkpoints`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    return data.data
  }

  async get_sync_committee_period_update(start_period, count) {
    const url = `${this.endopoint}/eth/v1/beacon/light_client/updates?start_period=${start_period}&count=${count}`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    return data
  }

  async get_finality_update() {
    const url = `${this.endopoint}/eth/v1/beacon/light_client/finality_update`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    return data.data
  }

  async get_optimistic_update() {
    const url = `${this.endopoint}/eth/v1/beacon/light_client/optimistic_update`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    return data.data
  }

  async get_bootstrap(block_root) {
    const url = `${this.endopoint}/eth/v1/beacon/light_client/bootstrap/${block_root}`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    return data.data
  }

  async get_finality_branch(state_id) {
    return this.get_state_proof(state_id, 105)
  }

  async get_latest_execution_payload_state_root_branch(state_id) {
    return this.get_state_proof(state_id, 898)
  }

  async get_next_sync_committee_branch(state_id) {
    return this.get_state_proof(state_id, 55)
  }

  async get_state_proof(state_id, gindex) {
    const url = `${this.endopoint}/eth/v1/beacon/light_client/single_proof/${state_id}?gindex=${gindex}`
    const headers = {'Content-Type': 'application/octet-stream'}
    const response = await fetch(url)

    for await (const chunk of response.body) {
      console.log(toHexString(chunk))
      const proof = hexProof(deserializeProof(chunk))
      console.log(proof)
      return proof
    }
  }

  async get_multi_proof(state_id, paths) {
    const url = `${this.endopoint}/eth/v1/beacon/light_client/proof/${state_id}?paths=${paths}`
    const headers = {'Content-Type': 'application/octet-stream'}
    const response = await fetch(url)

    for await (const chunk of response.body) {
      console.log(toHexString(chunk))
      const proof = multiProof(deserializeProof(chunk))
      console.log(proof)
      return proof
    }
  }
}

function hexProof(proof) {
  const hexJson = {
    type: proof.type,
    gindex: Number(proof.gindex),
    leaf: toHexString(proof.leaf),
    witnesses: proof.witnesses.map(toHexString),
  }
  return hexJson
}

function multiProof(proof) {
  const hexJson = {
    type: proof.type,
    offsets: proof.offsets,
    leaves: proof.leaves.map(toHexString)
  }
  return hexJson
}

module.exports.Eth2Client = Eth2Client
