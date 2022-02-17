const { expect } = require("chai")
const { waffle } = require("hardhat");
const { BigNumber } = require("ethers");
const { bootstrap } = require("./helper/fixture")
const chai = require("chai")
const { solidity } = waffle;
const { decodeJustification } = require("./helper/decode")
const { u8aToU8a } = require('@polkadot/util')

chai.use(solidity)
const log = console.log
let ethClient, subClient, bridge

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

describe("bridge e2e test: beefy light client", () => {

  before(async () => {
  })

  it("bootstrap", async () => {
    const clients = await bootstrap()
    ethClient = clients.ethClient
    subClient = clients.subClient
    bridge = clients.bridge
  })

  it("beefy", async () => {
    while (true) {
      const block = await subClient.beefy_block()
      if (block.justifications) {
        log(`BEEFY: ${block.block.header.number}, ${block.justifications.toString()}`)
        let js = JSON.parse(block.justifications.toString())
        for (let j of js) {
          if (j[0] == '0x42454546') {
            log(j[0], j[1])
            const justification = decodeJustification(u8aToU8a(j[1]))
            log(justification.toString())
          }
        }
      } else {
        log(`Skip block: ${block.block.header.number}`)
      }
      await sleep(5000)
    }
  })
})
