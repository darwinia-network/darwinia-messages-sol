const { expect } = require("chai")
const { waffle } = require("hardhat");
const { BigNumber } = require("ethers");
const { bootstrap } = require("./helper/fixture")
const chai = require("chai")
const { solidity } = waffle;

chai.use(solidity)
const log = console.log
let bscClient, subClient

describe("bridge e2e test: parlia light client", () => {

  before(async () => {
  })

  it("bootstrap", async () => {
    const clients = await bootstrap()
    bscClient = clients.bscClient
    subClient = clients.subClient
    bridge = clients.bridge
  })

  it("import finalized header", async () => {
    const old_finalized_checkpoint = await subClient.bscLightClient.finalized_checkpoint()
    log(old_finalized_checkpoint)
    const finalized_checkpoint_number = old_finalized_checkpoint.number.add(200)
    const finalized_checkpoint = await bscClient.get_block(finalized_checkpoint_number)
    const length = await subClient.bscLightClient.length_of_finalized_authorities()
    let headers = [finalized_checkpoint]
    for (let i=0; i < ~~length.div(2); i++) {
      const number = finalized_checkpoint_number.add(1)
      const header = await bscClient.get_block(number)
      headers.push(header)
    }
    log(headers)
    const tx = await subClient.bscLightClient.import_finalized_epoch_header(headers)
  })
})

