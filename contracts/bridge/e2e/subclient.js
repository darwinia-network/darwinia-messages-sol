const { ethers } = require("ethers");
let { ApiPromise, WsProvider, Keyring } = require('@polkadot/api');
const addresses = require("../bin/addr/local-dvm.json")

/**
 * The Substrate client for Bridge interaction
 */
class SubClient {

  constructor(http_endpoint, ws_endpoint) {
    this.dvm_provider = new ethers.providers.JsonRpcProvider(http_endpoint)
    console.log(ws_endpoint)
    this.sub_provider = new WsProvider(ws_endpoint)
  }

  async init() {
    this.api = await ApiPromise.create({
      provider: this.sub_provider
    })
    this.keyring = new Keyring({ type: 'sr25519' });
    this.alice = this.keyring.addFromUri('//Alice', { name: 'Alice' });

    // const ChainMessageCommitter = await artifacts.readArtifact("ChainMessageCommitter");
    // this.chainMessageCommitter = new ethers.Contract(addresses.ChainMessageCommitter, ChainMessageCommitter.abi, this.dvm_provider)

    // const LaneMessageCommitter = await artifacts.readArtifact("LaneMessageCommitter");
    // this.laneMessageCommitter = new ethers.Contract(addresses.LaneMessageCommitter, LaneMessageCommitter.abi, this.dvm_provider)

    // const FeeMarket = await artifacts.readArtifact("FeeMarket");
    // this.feeMarket = new ethers.Contract(addresses.FeeMarket, FeeMarket.abi, this.dvm_provider)

    // const BSCLightClient = await artifacts.readArtifact("BSCLightClient")
    // this.lightClient = new ethers.Contract(addresses.BSCLightClient, BSCLightClient.abi, this.dvm_provider)

    // const OutboundLane = await artifacts.readArtifact("OutboundLane")
    // this.outbound = new ethers.Contract(addresses.OutboundLane, OutboundLane.abi, this.dvm_provider)

    // const InboundLane = await artifacts.readArtifact("InboundLane")
    // this.inbound = new ethers.Contract(addresses.InboundLane, InboundLane.abi, this.dvm_provider)

    // let overrides = {
    //     value: ethers.utils.parseEther("100")
    // }
    // let prev = "0x0000000000000000000000000000000000000001"
    // privs.forEach(async (priv, i) => {
    //   let fee = fees[i]
    //   let signer = new ethers.Wallet(priv, this.dvm_provider)
    //   await this.feeMarket.connect(signer).enroll(prev, fee, overrides)
    //   prev = signer.address
    // })
  }

  async relay_header(state_root) {
    const tx = await this.api.tx.bsc.setStateRoot(state_root).signAndSend(this.alice)
    console.log(`Submitted with hash: ${tx}`)
  }

}

async function main() {
  const c = new SubClient('ws://192.168.2.100:9933', 'ws://192.168.2.100:9944')
  await c.init()
  await c.relay_header("0x0000000000000000000000000000000000000000000000000000000000000001")
}

main().catch(console.error).finally(() => process.exit())

module.exports.SubClient = SubClient;
