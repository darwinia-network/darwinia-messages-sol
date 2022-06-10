const { expect } = require("chai")
const { waffle } = require("hardhat");
const { BigNumber } = require("ethers");
const { bootstrap } = require("./helper/fixture")
const chai = require("chai")
const { solidity } = waffle;

chai.use(solidity)
const log = console.log
let ethClient, eth2Client, subClient, bridge

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms)
  })
}

describe("bridge e2e test: beacon light client", () => {

  before(async () => {
  })

  it("bootstrap", async () => {
    const clients = await bootstrap()
    ethClient = clients.ethClient
    bscClient = clients.bscClient
    eth2Client = clients.eth2Client
    subClient = clients.subClient
    bridge = clients.bridge
  })

  it("import old finalized header", async () => {
    const old_finalized_header = await subClient.beaconLightClient.finalized_header()
    log('old_finalized_header', old_finalized_header)
    const old_finalized_header_root = await eth2Client.get_beacon_block_root(old_finalized_header.slot)
    const snapshot = await eth2Client.get_light_client_snapshot(old_finalized_header_root)
    const current_sync_committee = snapshot.current_sync_committee
    const old_period = old_finalized_header.slot.div(32).div(256)

    let attested_header_slot = old_finalized_header.slot.add(96)
    // let attested_header_slot = old_finalized_header.slot.add(128)
    let attested_header = await eth2Client.get_header(attested_header_slot)
    while (!attested_header) {
      attested_header_slot = attested_header_slot.add(1)
      attested_header = await eth2Client.get_header(attested_header_slot)
    }
    log('attested_header_slot', attested_header_slot.toNumber())
    log('attested_header', attested_header)

    let sync_aggregate_slot = attested_header_slot.add(1)
    let sync_aggregate_header = await eth2Client.get_header(sync_aggregate_slot)
    while (!sync_aggregate_header) {
      sync_aggregate_slot = sync_aggregate_slot.add(1)
      sync_aggregate_header = await eth2Client.get_header(sync_aggregate_slot)
    }
    log('sync_aggregate_slot', sync_aggregate_slot.toNumber())
    log('sync_aggregate_header', sync_aggregate_header)
    let sync_aggregate_block = await eth2Client.get_beacon_block(sync_aggregate_slot)
    log('sync_aggregate_block', sync_aggregate_block)
    const new_period = sync_aggregate_slot.div(32).div(256)
    expect(~~new_period).to.eq(~~old_period)

    let sync_aggregate = sync_aggregate_block.message.body.sync_aggregate
    log(sync_aggregate)
    let sync_committee_bits = []
    sync_committee_bits.push(sync_aggregate.sync_committee_bits.slice(0, 66))
    sync_committee_bits.push('0x' + sync_aggregate.sync_committee_bits.slice(66))
    sync_aggregate.sync_committee_bits = sync_committee_bits;
    log(sync_aggregate)

    let cp = await eth2Client.get_checkpoint(attested_header_slot)
    log('cp', cp)
    let finalized_header_root = cp.finalized.root
    let finalized_header = await eth2Client.get_header(finalized_header_root)
    log('finalized_header', finalized_header)

    const finalized_block = await eth2Client.get_beacon_block(finalized_header.root)
    const finality_branch = await eth2Client.get_finality_branch(attested_header_slot)

    const latest_execution_payload_state_root = finalized_block.message.body.execution_payload.state_root
    const latest_execution_payload_state_root_branch = await eth2Client.get_latest_execution_payload_state_root_branch(finalized_header.header.message.slot)
    const fork_version = await eth2Client.get_fork_version(attested_header_slot)
    log('fork_version', fork_version)

    const finalized_header_update = {
      attested_header: attested_header.header.message,
      current_sync_committee,
      finalized_header: finalized_header.header.message,
      finality_branch: finality_branch.witnesses,
      latest_execution_payload_state_root,
      latest_execution_payload_state_root_branch: latest_execution_payload_state_root_branch.witnesses,
      sync_aggregate: sync_aggregate,
      fork_version: fork_version.current_version
    }

    console.log(finalized_header_update)
    // console.log(JSON.stringify(current_sync_committee.pubkeys, null, 2))

    // gasLimit: 10000000,
    // gasPrice: 1300000000
    const tx = await subClient.beaconLightClient.import_finalized_header(finalized_header_update)
    console.log(tx)

    const new_finalized_header = await subClient.beaconLightClient.finalized_header()

    console.log(new_finalized_header)
    expect(finalized_header.header.message.slot).to.eq(new_finalized_header.slot)
    expect(finalized_header.header.message.proposer_index).to.eq(new_finalized_header.proposer_index)
    expect(finalized_header.header.message.parent_root).to.eq(new_finalized_header.parent_root)
    expect(finalized_header.header.message.state_root).to.eq(new_finalized_header.state_root)
    expect(finalized_header.header.message.body_root).to.eq(new_finalized_header.body_root)

  })
})

