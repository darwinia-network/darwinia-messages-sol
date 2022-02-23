const { expect } = require("chai")
const { waffle } = require("hardhat");
const { BigNumber } = require("ethers");
const { bootstrap } = require("./helper/fixture")
const chai = require("chai")
const { solidity } = waffle;
const { decodeJustification } = require("./helper/decode")
const { encodeCommitment, encodeBeefyPayload } = require("./helper/encode")
const { u8aToBuffer, u8aToHex } = require('@polkadot/util')

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
    // const unsubscribe = await subClient.api.rpc.beefy.subscribeJustifications((b) => {
    //   console.log(`BEEFY: #${b}`);
    //   unsubscribe();
    //   process.exit(0);
    // });
  })

  it("set committer", async () => {
    subClient.set_chain_committer()
  })

  it("beefy", async () => {
    let c, s, hash
    while (!c) {
      const block = await subClient.beefy_block()
      hash = block.block.header.hash.toHex()
      if (block.justifications.toString()) {
        log(`BEEFY: ${block.block.header.number}, ${block.justifications.toString()}`)
        let js = JSON.parse(block.justifications.toString())
        for (let j of js) {
          if (j[0] == '0x42454546') {
            const justification = decodeJustification(j[1])
            c = justification.toJSON().v1.commitment
            const cc = encodeCommitment(c).toHex()
            log(`Encoded commitment: ${cc}`)
            let sig = justification.toJSON().v1.signatures[0].s
            let v = parseInt(sig.slice(-2), 16);
            v+=27
            s = sig.slice(0, -2) + v.toString(16)
            break
          }
        }
      } else {
        log(`Skip block: ${block.block.header.number}`)
      }
      await sleep(1000)
    }
    log(c)
    const beefy_payload = await subClient.beefy_payload(c.blockNumber, hash)
    const p = encodeBeefyPayload(beefy_payload)
    log(`Encoded beefy payload: ${p.toHex()}`)
    const beefy_commitment = {
      payload: beefy_payload,
      blockNumber: c.blockNumber,
      validatorSetId: c.validatorSetId
    }
    log(beefy_payload)
    const authoritirs = await subClient.beefy_authorities()
    const addr = ethers.utils.computeAddress(authoritirs[0])
    await ethClient.relay_real_head(beefy_commitment, s, addr)
    const message_root = await ethClient.lightClient.latestChainMessagesRoot()
    expect(message_root).to.eq(beefy_payload.messageRoot)
  })
})
