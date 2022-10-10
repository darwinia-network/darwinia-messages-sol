const { toHexString } = require('@chainsafe/ssz')
const { expect } = require("chai")
const { waffle } = require("hardhat")
const { BigNumber } = require("ethers")
const { bootstrap } = require("./helper/fixture")
const chai = require("chai")
const { solidity } = waffle

chai.use(solidity)
const log = console.log
let eth2Client, subClient

describe("bridge e2e test: beacon light client", () => {

  before(async () => {
  })

  it("bootstrap", async () => {
    const clients = await bootstrap()
    eth2Client = clients.eth2Client
    subClient = clients.subClient
  })

  it("import finalized header", async () => {
    const x = await import("@chainsafe/lodestar-types")
    const phase0 = x.ssz.phase0
    const bellatrix = x.ssz.allForks.bellatrix
    const BeaconBlockHeader = phase0.BeaconBlockHeader
    const BeaconBlockBody = bellatrix.BeaconBlockBody

    const old_finalized_header = await subClient.beaconLightClient.finalized_header()
    const old_period = old_finalized_header.slot.div(32).div(256)

    const finalized_header_ssz = BeaconBlockHeader.fromJson({
      slot: old_finalized_header.slot.toNumber(),
      proposer_index: old_finalized_header.proposer_index.toNumber(),
      parent_root: old_finalized_header.parent_root,
      state_root: old_finalized_header.state_root,
      body_root: old_finalized_header.body_root
    })

    const finalized_header_root = toHexString(BeaconBlockHeader.hashTreeRoot(finalized_header_ssz))

    // const snapshot = await eth2Client.get_bootstrap(old_finalized_header.root)
    // const current_sync_committee = snapshot.current_sync_committee

    // let sync_aggregate_slot = attested_header_slot.add(1)
    // let sync_aggregate_header = await eth2Client.get_header(sync_aggregate_slot)
    // while (!sync_aggregate_header) {
    //   sync_aggregate_slot = sync_aggregate_slot.add(1)
    //   sync_aggregate_header = await eth2Client.get_header(sync_aggregate_slot)
    // }
    // let sync_aggregate_block = await eth2Client.get_beacon_block(sync_aggregate_slot)
    // const new_period = sync_aggregate_slot.div(32).div(256)
    // expect(~~new_period).to.eq(~~old_period)

    // let sync_aggregate = sync_aggregate_block.message.body.sync_aggregate
    // let sync_committee_bits = []
    // sync_committee_bits.push(sync_aggregate.sync_committee_bits.slice(0, 66))
    // sync_committee_bits.push('0x' + sync_aggregate.sync_committee_bits.slice(66))
    // sync_aggregate.sync_committee_bits = sync_committee_bits;

    // let cp = await eth2Client.get_checkpoint(attested_header_slot)
    // let finalized_header_root = cp.finalized.root
    // let finalized_header = await eth2Client.get_header(finalized_header_root)

    // const finalized_block = await eth2Client.get_beacon_block(finalized_header.root)
    // const finality_branch = await eth2Client.get_finality_branch(attested_header_slot)

    // const fork_version = await eth2Client.get_fork_version(sync_aggregate_slot)

    // const finalized_header_update = {
    //   attested_header: attested_header.header.message,
    //   signature_sync_committee: current_sync_committee,
    //   finalized_header: finalized_header.header.message,
    //   finality_branch: finality_branch.witnesses,
    //   sync_aggregate: sync_aggregate,
    //   fork_version: fork_version.current_version,
    //   signature_slot: sync_aggregate_slot
    // }

    // gasLimit: 10000000,
    // gasPrice: 1300000000
    // const tx = await subClient.beaconLightClient.import_finalized_header(finalized_header_update)

    // const new_finalized_header = await subClient.beaconLightClient.finalized_header()

    // expect(finalized_header.header.message.slot).to.eq(new_finalized_header.slot)
    // expect(finalized_header.header.message.proposer_index).to.eq(new_finalized_header.proposer_index)
    // expect(finalized_header.header.message.parent_root).to.eq(new_finalized_header.parent_root)
    // expect(finalized_header.header.message.state_root).to.eq(new_finalized_header.state_root)
    // expect(finalized_header.header.message.body_root).to.eq(new_finalized_header.body_root)
  })

  it.skip("import next_sync_committee", async () => {
    const old_finalized_header = await subClient.beaconLightClient.finalized_header()
    const old_period = old_finalized_header.slot.div(32).div(256)

    const sync_change = await eth2Client.get_sync_committee_period_update(~~old_period, 1)
    const next_sync = sync_change[0]
    const next_sync_committee = next_sync.next_sync_committee
    const next_sync_committee_branch = await eth2Client.get_next_sync_committee_branch(old_finalized_header.slot)

    const sync_committee_period_update = {
      next_sync_committee,
      next_sync_committee_branch: next_sync_committee_branch.witnesses
    }

    const tx = await subClient.beaconLightClient.import_next_sync_committee(sync_committee_period_update, { gasLimit: 6000000 })
    const next_period = ~~old_period + 1
    const next_period_sync_committee_root = await subClient.beaconLightClient.sync_committee_roots(next_period)
    log(next_period_sync_committee_root)
  })

  it.skip("import latest_execution_payload_state_root on execution layer", async () => {
    const finalized_header = await subClient.beaconLightClient.finalized_header()
    const finalized_block = await eth2Client.get_beacon_block(finalized_header.slot)

    const latest_execution_payload_state_root = finalized_block.message.body.execution_payload.state_root
    const latest_execution_payload_state_root_branch = await eth2Client.get_latest_execution_payload_state_root_branch(finalized_header.slot)

    const execution_payload_state_root_update = {
      latest_execution_payload_state_root,
      latest_execution_payload_state_root_branch: latest_execution_payload_state_root_branch.witnesses
    }

    const tx = await subClient.executionLayer.import_latest_execution_payload_state_root(execution_payload_state_root_update)
    const state_root = await subClient.executionLayer.state_root()
    log(state_root)
    expect(latest_execution_payload_state_root).to.eq(state_root)
  })
})

