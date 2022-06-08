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
    eth2Client = clients.eth2Client
    subClient = clients.subClient
    bridge = clients.bridge
  })

  it("import finalized header", async () => {
  })
})
