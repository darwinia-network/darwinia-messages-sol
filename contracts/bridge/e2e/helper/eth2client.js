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
    console.log(data)
    return data
  }

  async get_beacon_block(id) {
    const url = `${this.endopoint}/eth/v2/beacon/blocks/${id}`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    console.log(data)
    return data.data
  }

  async get_beacon_block_root(id) {
    const url = `${this.endopoint}/eth/v1/beacon/blocks/${id}/root`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    console.log(data)
    return data.data
  }

  async get_genesis() {
    const url = `${this.endopoint}/eth/v1/beacon/genesis`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    console.log(data)
    return data
  }

  async get_current_fork_version(id) {
    const url = `${this.endopoint}/eth/v1/beacon/states/${id}/fork`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    console.log(data)
    return data
  }

  async get_finalized_checkpoint() {
    return this.get_checkpoint('finalized')
  }

  async get_checkpoint(id) {
    const url = `${this.endopoint}/eth/v1/beacon/states/${id}/finality_checkpoints`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    console.log(data)
    return data
  }

  async get_sync_committee_period_update(from, to) {
    const url = `${this.endopoint}/eth/v1/lightclient/committee_updates?from=${from}&to=${to}`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    console.log(data)
    return data
  }

  async get_light_client_snapshot(block_root) {
    const url = `${this.endopoint}/eth/v1/lightclient/snapshot/${block_root}`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    console.log(data)
    return data.data
  }

  async get_latest_finalized_update() {
    const url = `${this.endopoint}/eth/v1/lightclient/latest_finalized_head_update/`
    const headers = {'accept': 'application/json'}
    const response = await fetch(url)
    const data = await response.json()
    console.log(data)
    return data
  }

  async get_finality_branch(state_id) {
    const paths = [["finalized_checkpoint", "root"]]
    return this.get_state_proof(state_id, paths)
  }

  async get_state_proof(state_id, json_paths) {
    const paths = json_paths.map((path) => JSON.stringify(path))
    const url = `${this.endopoint}/eth/v1/lightclient/proof/${state_id}?paths=${paths}`
    const headers = {'Content-Type': 'application/octet-stream'}
    const response = await fetch(url)

    for await (const chunk of response.body) {
      const proof = hexProof(deserializeProof(chunk))
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

module.exports.Eth2Client = Eth2Client
