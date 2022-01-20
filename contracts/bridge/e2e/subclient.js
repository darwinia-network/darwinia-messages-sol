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

  async init(wallets, fees) {
    this.api = await ApiPromise.create({
      provider: this.sub_provider
    })
    this.keyring = new Keyring({ type: 'sr25519' });
    this.alice = this.keyring.addFromUri('//Alice', { name: 'Alice' });

    const ChainMessageCommitter = await artifacts.readArtifact("ChainMessageCommitter");
    this.chainMessageCommitter = new ethers.Contract(addresses.ChainMessageCommitter, ChainMessageCommitter.abi, this.dvm_provider)

    const LaneMessageCommitter = await artifacts.readArtifact("LaneMessageCommitter");
    this.laneMessageCommitter = new ethers.Contract(addresses.LaneMessageCommitter, LaneMessageCommitter.abi, this.dvm_provider)

    const FeeMarket = await artifacts.readArtifact("FeeMarket");
    this.feeMarket = new ethers.Contract(addresses.FeeMarket, FeeMarket.abi, this.dvm_provider)

    const BSCLightClient = await artifacts.readArtifact("BSCLightClient")
    const lightClient = new ethers.Contract(addresses.BSCLightClient, BSCLightClient.abi, this.dvm_provider)

    const OutboundLane = await artifacts.readArtifact("OutboundLane")
    const outbound = new ethers.Contract(addresses.OutboundLane, OutboundLane.abi, this.dvm_provider)

    const InboundLane = await artifacts.readArtifact("InboundLane")
    const inbound = new ethers.Contract(addresses.InboundLane, InboundLane.abi, this.dvm_provider)

    let prev = "0x0000000000000000000000000000000000000001"
    for(let i=0; i<wallets.length; i++) {
      let fee = fees[i]
      let signer = wallets[i]
      await this.feeMarket.connect(signer.connect(this.dvm_provider)).enroll(prev, fee, {
        value: ethers.utils.parseEther("100")
      })
      prev = signer.address
    }

    let signer = wallets[0].connect(this.dvm_provider)
    this.lightClient = lightClient.connect(signer)
    this.outbound = outbound.connect(signer)
    this.inbound = inbound.connect(signer)
  }

  async relay_header(state_root) {
    const tx = await this.api.tx.bsc.setStateRoot(state_root).signAndSend(this.alice)
    console.log(`Header relay tx submitted with hash: ${tx}`)
  }

  async block_header() {
    const header = await this.api.rpc.chain.getHeader();
    console.log(`last block #${header.number} has hash ${header.hash}`);
    return header
  }

}

module.exports.SubClient = SubClient;
