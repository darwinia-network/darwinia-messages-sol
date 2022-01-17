const { expect } = require("chai")
const { solidity } = require("ethereum-waffle")
const { bootstrap } = require("./fixture")
const chai = require("chai")

chai.use(solidity)
const log = console.log
let ethClient, subClient

describe("bridge e2e test: verify message storage proof", () => {

  before(async () => {
    const clients = await bootstrap()
    ethClient = clients.ethClient
    subClient = clients.subClient
  })

  it("0", async function () {
    // await send_message(sourceOutbound, 1)
  })

})
