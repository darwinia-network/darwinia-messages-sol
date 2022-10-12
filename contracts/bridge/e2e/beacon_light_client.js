const { toHexString, ListCompositeType, ByteVectorType, ByteListType } = require('@chainsafe/ssz')
const { expect } = require("chai")
const { waffle } = require("hardhat")
const { BigNumber } = require("ethers")
const { bootstrap } = require("./helper/fixture")
const chai = require("chai")
const { solidity } = waffle

chai.use(solidity)
const log = console.log
let eth2Client, subClient

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
      slot:            old_finalized_header.slot.toNumber(),
      proposer_index:  old_finalized_header.proposer_index.toNumber(),
      parent_root:     old_finalized_header.parent_root,
      state_root:      old_finalized_header.state_root,
      body_root:       old_finalized_header.body_root
    })

    const finalized_header_root = toHexString(BeaconBlockHeader.hashTreeRoot(finalized_header_ssz))

    const snapshot = await eth2Client.get_bootstrap(finalized_header_root)
    const current_sync_committee = snapshot.current_sync_committee

    const finality_update = await eth2Client.get_finality_update()
    const attested_header_slot = finality_update.attested_header.slot

    let sync_aggregate_slot = ~~attested_header_slot + 1
    let sync_aggregate_header = await eth2Client.get_header(sync_aggregate_slot)
    while (!sync_aggregate_header) {
      sync_aggregate_slot = sync_aggregate_slot + 1
      sync_aggregate_header = await eth2Client.get_header(sync_aggregate_slot)
    }

    const new_period = sync_aggregate_slot / 32 / 256
    expect(~~new_period).to.eq(~~old_period)

    let sync_aggregate = finality_update.sync_aggregate
    let sync_committee_bits = []
    sync_committee_bits.push(sync_aggregate.sync_committee_bits.slice(0, 66))
    sync_committee_bits.push('0x' + sync_aggregate.sync_committee_bits.slice(66))
    sync_aggregate.sync_committee_bits = sync_committee_bits;

    const finalized_header = finality_update.finalized_header
    const finality_branch = finality_update.finality_branch

    const fork_version = await eth2Client.get_fork_version(sync_aggregate_slot)

    const finalized_header_update = {
      attested_header:           finality_update.attested_header,
      signature_sync_committee:  current_sync_committee,
      finalized_header:          finalized_header,
      finality_branch:           finality_branch,
      sync_aggregate:            sync_aggregate,
      fork_version:              fork_version.current_version,
      signature_slot:            sync_aggregate_slot
    }

    // gasLimit: 10000000,
    // gasPrice: 1300000000
    const tx = await subClient.beaconLightClient.import_finalized_header(finalized_header_update, {gasLimit: 10000000})

    await expect(tx)
      .to.emit(subClient.executionLayer, "FinalizedHeaderImported")
      .withArgs(
        finalized_header.slot,
        finalized_header.proposer_index,
        finalized_header.parent_root,
        finalized_header.state_root,
        finalized_header.body_root
      )
  })

  it("import next_sync_committee", async () => {
    const old_finalized_header = await subClient.beaconLightClient.finalized_header()
    let old_period = ~~old_finalized_header.slot.div(32).div(256)
    let next_period = old_period + 1
    let s = await subClient.beaconLightClient.sync_committee_roots(next_period)
    while (s != '0x0000000000000000000000000000000000000000000000000000000000000000') {
      old_period++
      next_period++
      s = await subClient.beaconLightClient.sync_committee_roots(next_period)
    }

    const sync_change = await eth2Client.get_sync_committee_period_update(old_period, 1)
    const next_sync = sync_change[0]

    const sync_committee_period_update = {
      next_sync_committee: next_sync.next_sync_committee,
      next_sync_committee_branch: next_sync.next_sync_committee_branch
    }

    const x = await import("@chainsafe/lodestar-types")
    const phase0 = x.ssz.phase0
    const altair = x.ssz.altair
    const BeaconBlockHeader = phase0.BeaconBlockHeader
    const SyncCommittee = altair.SyncCommittee

    const f = next_sync.finalized_header
    const finalized_header_ssz = BeaconBlockHeader.fromJson({
      slot:            f.slot,
      proposer_index:  f.proposer_index,
      parent_root:     f.parent_root,
      state_root:      f.state_root,
      body_root:       f.body_root
    })
    const finalized_header_root = toHexString(BeaconBlockHeader.hashTreeRoot(finalized_header_ssz))
    const snapshot = await eth2Client.get_bootstrap(finalized_header_root)
    const current_sync_committee = snapshot.current_sync_committee

    const attested_header_slot = next_sync.attested_header.slot
    let sync_aggregate_slot = ~~attested_header_slot + 1
    let sync_aggregate_header = await eth2Client.get_header(sync_aggregate_slot)
    while (!sync_aggregate_header) {
      sync_aggregate_slot = sync_aggregate_slot + 1
      sync_aggregate_header = await eth2Client.get_header(sync_aggregate_slot)
    }

    let sync_aggregate = next_sync.sync_aggregate
    let sync_committee_bits = []
    sync_committee_bits.push(sync_aggregate.sync_committee_bits.slice(0, 66))
    sync_committee_bits.push('0x' + sync_aggregate.sync_committee_bits.slice(66))
    sync_aggregate.sync_committee_bits = sync_committee_bits;

    const finalized_header_update = {
      attested_header:           next_sync.attested_header,
      signature_sync_committee:  current_sync_committee,
      finalized_header:          next_sync.finalized_header,
      finality_branch:           next_sync.finality_branch,
      sync_aggregate:            sync_aggregate,
      fork_version:              next_sync.fork_version,
      signature_slot:            sync_aggregate_slot
    }

    const tx = await subClient.beaconLightClient.import_next_sync_committee(finalized_header_update, sync_committee_period_update, { gasLimit: 10000000 })

    const next_sync_committee = SyncCommittee.fromJson(next_sync.next_sync_committee)
    const next_sync_committee_root = toHexString(SyncCommittee.hashTreeRoot(next_sync_committee))

    await expect(tx)
      .to.emit(subClient.beaconLightClient, "NextSyncCommitteeImported")
      .withArgs(next_period, next_sync_committee_root)
  })

  it("import latest_execution_payload_state_root on execution layer", async () => {
    const x = await import("@chainsafe/lodestar-types")
    const ssz = x.ssz
    const BeaconBlockBody = ssz.allForks.bellatrix.BeaconBlockBody

    const finalized_header = await subClient.beaconLightClient.finalized_header()

    const block = await eth2Client.get_beacon_block(finalized_header.slot)
    const b = block.body
    const p = b.execution_payload

    const ProposerSlashing = get_ssz_type(ssz, 'ProposerSlashing', 'phase0')
    const ProposerSlashings = new ListCompositeType(ProposerSlashing, 16)
    const AttesterSlashing = get_ssz_type(ssz, 'AttesterSlashing', 'phase0')
    const AttesterSlashings = new ListCompositeType(AttesterSlashing, 2)
    const Attestation = get_ssz_type(ssz, 'Attestation', 'phase0')
    const Attestations = new ListCompositeType(Attestation, 128)
    const Deposit = get_ssz_type(ssz, 'Deposit', 'phase0')
    const Deposits = new ListCompositeType(Deposit, 16)
    const SignedVoluntaryExit = get_ssz_type(ssz, 'SignedVoluntaryExit', 'phase0')
    const SignedVoluntaryExits = new ListCompositeType(SignedVoluntaryExit, 16)

    const LogsBloom = new ByteVectorType(256)
    const ExtraData = new ByteListType(32)

    const body = {
        randao_reveal:       hash_tree_root(x, 'BLSSignature', 'ssz', b.randao_reveal),
        eth1_data:           hash_tree_root(ssz, 'Eth1Data', 'phase0', b.eth1_data),
        graffiti:            b.graffiti,
        proposer_slashings:  hash(ProposerSlashings, b.proposer_slashings),
        attester_slashings:  hash(AttesterSlashings, b.attester_slashings),
        attestations:        hash(Attestations, b.attestations),
        deposits:            hash(Deposits, b.deposits),
        voluntary_exits:     hash(SignedVoluntaryExits, b.voluntary_exits),
        sync_aggregate:      hash_tree_root(ssz, 'SyncAggregate', 'altair', b.sync_aggregate),

        execution_payload:   {
          parent_hash:       p.parent_hash,
          fee_recipient:     p.fee_recipient,
          state_root:        p.state_root,
          receipts_root:     p.receipts_root,
          logs_bloom:        hash(LogsBloom, p.logs_bloom),
          prev_randao:       p.prev_randao,
          block_number:      p.block_number,
          gas_limit:         p.gas_limit,
          gas_used:          p.gas_used,
          timestamp:         p.timestamp,
          extra_data:        hash(ExtraData, p.extra_data),
          base_fee_per_gas:  p.base_fee_per_gas,
          block_hash:        p.block_hash,
          transactions:      hash_tree_root(ssz, 'Transactions', 'bellatrix', p.transactions)
        }
    }

    const tx = await subClient.executionLayer.import_latest_execution_payload_state_root(body)
    await expect(tx)
      .to.emit(subClient.executionLayer, "LatestExecutionPayloadStateRootImported")
      .withArgs(p.state_root)
  })
})

