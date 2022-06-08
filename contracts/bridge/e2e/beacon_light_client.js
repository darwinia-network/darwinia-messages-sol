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

  it("import finalized header", async () => {
    const old_finalized_header = await subClient.beaconLightClient.finalized_header()
    console.log(old_finalized_header)
    const old_finalized_header_root = await eth2Client.get_beacon_block_root(old_finalized_header.slot)
    const snapshot = await eth2Client.get_light_client_snapshot(old_finalized_header_root)
    const current_sync_committtee = snapshot.current_sync_committtee
    let finalized_header_slot = old_finalized_header.slot.add(32)
    let finalized_header = await eth2Client.get_header(finalized_header_slot)
    while (!finalized_header) {
      finalized_header_slot = finalized_header_slot.sub(1)
      finalized_header = await eth2Client.get_header(finalized_header_slot)
      console.log(finalized_header.header.message)
    }
    let attested_header_slot = old_finalized_header.slot.add(96)
    let attested_header = await eth2Client.get_header(attested_header_slot)
    while (!attested_header && attested_header.header.message.finalized_checkpoint) {
        attested_header_slot = attested_header_slot.sub(1)
        attested_header = await eth2Client.get_header(attested_header_slot)
        console.log(attested_header.header.message)
    }
    let attested_block = await eth2Client.get_beacon_block(attested_header_slot)
    let attested_block_body = attested_block.message.body
    let sync_aggregate = attested_block_body.sync_aggregate
    let finalized_checkpoint = attested_block_body.finalized_checkpoint
    console.log(sync_aggregate)
    console.log(finalized_checkpoint)

    // const finaliy_branch = await eth2Client.get_finality_branch(attested_header_slot)

  })
})
