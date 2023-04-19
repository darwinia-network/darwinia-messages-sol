const { toHexString, ListCompositeType, ByteVectorType, ByteListType } = require('@chainsafe/ssz')
const { expect } = require("chai")
const { waffle } = require("hardhat")
const { BigNumber } = require("ethers")
const { bootstrap } = require("./helper/fixture")
const chai = require("chai")
const { solidity } = waffle

chai.use(solidity)
const log = console.log
let eth2Client, subClient, bridge

const target  = process.env.TARGET || 'local'

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

const compute_fork_version = (epoch) => {
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

describe("bridge e2e test: beacon light client", () => {

  before(async () => {
  })

  it("bootstrap", async () => {
    const clients = await bootstrap()
    eth2Client = clients.eth2Client
    subClient = clients.subClient
    bridge = clients.bridge
  })

  it("import finalized header", async () => {
    const [tx, finalized_header_update] = await bridge.blc_import_finalized_header()
    console.log(tx)

    await expect(tx)
      .to.emit(subClient.eth.lightclient, "FinalizedHeaderImported")
      .withArgs(
        finalized_header_update.finalized_header.beacon
      )

    await expect(tx)
      .to.emit(subClient.eth.lightclient, "FinalizedExecutionPayloadHeaderImported")
      .withArgs(
        finalized_header_update.finalized_header.execution.block_number,
        finalized_header_update.finalized_header.execution.state_root
      )
  })

  it.skip("import next_sync_committee", async () => {
    const x = await import("@chainsafe/lodestar-types")
    const SyncCommittee = x.ssz.altair.SyncCommittee

    const old_finalized_header = await subClient.eth.lightclient.finalized_header()
    let old_period = ~~old_finalized_header.slot.div(32).div(256)
    let now_header = await eth2Client.get_header("head")
    let now_period = ~~(now_header.header.message.slot / 32 / 256)
    if (old_period == now_period) throw new Error("synced")

    const [tx, sync_committee_period_update] = await bridge.blc_import_next_sync_committee(old_period)

    console.log(tx)

    const next_sync_committee = SyncCommittee.fromJson(sync_committee_period_update.next_sync_committee)
    const next_sync_committee_root = toHexString(SyncCommittee.hashTreeRoot(next_sync_committee))

    await expect(tx)
      .to.emit(subClient.eth.lightclient, "NextSyncCommitteeImported")
      .withArgs(next_period, next_sync_committee_root)
  })
})

